/*
 * steam-toast-place - keep Steam's notification toasts out of the bar.
 *
 * Steam ("friend started playing", new message, ...) draws its popups as its
 * own override-redirect X11 window out of steamwebhelper, hard against the
 * bottom-right corner of the screen - right on top of the bar. Sway does not
 * manage override-redirect windows, so window rules cannot move them. This
 * helper watches for those windows and moves them with plain X11 calls, which
 * work whether or not a compositor manages the window.
 *
 * Placement: bottom-right of the main output, just above the bar, stacked
 * upwards when several toasts are on screen at once.
 *
 * A window is a toast when its title names it as one, or - toasts arrive
 * unnamed - when it is a small override-redirect window of a Steam process
 * that Steam has parked in the screen corner. The corner test keeps Steam's
 * other transient windows (menus, tooltips, UI layers) out of it.
 *
 * Build:   gcc -O2 -o steam-toast-place steam-toast-place.c -lX11
 * Install: cp steam-toast-place ~/.local/bin/
 * Log:     /tmp/steam-toast-place.log
 */

#define _GNU_SOURCE
#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include <errno.h>
#include <fcntl.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/file.h>
#include <sys/select.h>
#include <time.h>
#include <unistd.h>

/* Placement, in X11 layout coordinates (xrandr shows the same as sway). */
static const int OUTPUT_X = 2560; /* DP-1, the main monitor */
static const int OUTPUT_W = 2560;
static const int OUTPUT_H = 1440;
static const int BAR_H = 35; /* waybar is along the bottom of the output */
static const int GAP = 10;   /* margin from the right edge and from the bar */

/* What a toast looks like (Steam draws them 425x105). */
static const int TOAST_MIN_W = 350, TOAST_MAX_W = 650;
static const int TOAST_MIN_H = 80, TOAST_MAX_H = 350;
static const int CORNER_RANGE = 300; /* "parked in the screen corner" */

#define MAX_TOASTS 8
static const double ENFORCE_SECONDS = 15.0; /* keep re-pinning a toast this long */
static const double TICK_SECONDS = 0.25;

static FILE *logf;

struct toast {
    Window w;
    int width, height;
    double born;
};

static void logmsg(const char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    vfprintf(logf, fmt, ap);
    va_end(ap);
    fputc('\n', logf);
    fflush(logf);
}

static double now_s(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + (double)ts.tv_nsec / 1e9;
}

/* Read a window property as a C string (format-8 properties only). */
static char *get_prop(Display *dpy, Window w, Atom atom)
{
    Atom type = None;
    int fmt = 0;
    unsigned long n = 0, after = 0;
    unsigned char *data = NULL;

    if (XGetWindowProperty(dpy, w, atom, 0, 1024, False, AnyPropertyType,
                           &type, &fmt, &n, &after, &data) != Success || !data)
        return NULL;

    char *s = NULL;
    if (n > 0 && fmt == 8) {
        s = malloc(n + 1);
        if (s) {
            memcpy(s, data, n);
            s[n] = '\0';
        }
    }
    XFree(data);
    return s;
}

static char *window_name(Display *dpy, Window w)
{
    Atom net_name = XInternAtom(dpy, "_NET_WM_NAME", True);
    char *name = (net_name != None) ? get_prop(dpy, w, net_name) : NULL;
    if (!name)
        name = get_prop(dpy, w, XA_WM_NAME);
    return name;
}

static long window_pid(Display *dpy, Window w)
{
    Atom pid_atom = XInternAtom(dpy, "_NET_WM_PID", True);
    if (pid_atom == None)
        return -1;

    Atom type = None;
    int fmt = 0;
    unsigned long n = 0, after = 0;
    unsigned char *data = NULL;
    if (XGetWindowProperty(dpy, w, pid_atom, 0, 1, False, AnyPropertyType,
                           &type, &fmt, &n, &after, &data) != Success || !data)
        return -1;

    long pid = (n > 0 && fmt == 32) ? (long)((unsigned long *)data)[0] : -1;
    XFree(data);
    return pid;
}

/* WM_CLASS is two NUL-terminated strings: instance, then class. */
static void window_class(Display *dpy, Window w, char **instance, char **class)
{
    *instance = *class = NULL;

    Atom type = None;
    int fmt = 0;
    unsigned long n = 0, after = 0;
    unsigned char *data = NULL;
    if (XGetWindowProperty(dpy, w, XA_WM_CLASS, 0, 1024, False,
                           AnyPropertyType, &type, &fmt, &n, &after,
                           &data) != Success || !data || n == 0 || fmt != 8) {
        if (data)
            XFree(data);
        return;
    }

    size_t inst_len = strnlen((char *)data, n);
    *instance = strndup((char *)data, inst_len);
    if (inst_len + 1 < n) /* a second, non-empty string is present */
        *class = strndup((char *)data + inst_len + 1, n - inst_len - 1);
    XFree(data);
}

static char *window_type_name(Display *dpy, Window w)
{
    Atom type_atom = XInternAtom(dpy, "_NET_WM_WINDOW_TYPE", True);
    if (type_atom == None)
        return NULL;
    Atom actual = None;
    int fmt = 0;
    unsigned long n = 0, after = 0;
    unsigned char *data = NULL;
    if (XGetWindowProperty(dpy, w, type_atom, 0, 1, False, XA_ATOM, &actual,
                           &fmt, &n, &after, &data) != Success || !data || n == 0)
        return NULL;
    char *name = XGetAtomName(dpy, *(Atom *)data);
    XFree(data);
    return name;
}

static int pid_looks_like_steam(long pid)
{
    if (pid <= 0)
        return 0;
    char path[64], buf[4096];
    snprintf(path, sizeof path, "/proc/%ld/cmdline", pid);
    int fd = open(path, O_RDONLY);
    if (fd < 0)
        return 0;
    ssize_t n = read(fd, buf, sizeof buf - 1);
    close(fd);
    if (n <= 0)
        return 0;
    buf[n] = '\0';
    return strcasestr(buf, "steam") != NULL;
}

static int is_toast_sized(const XWindowAttributes *a)
{
    return a->width >= TOAST_MIN_W && a->width <= TOAST_MAX_W &&
           a->height >= TOAST_MIN_H && a->height <= TOAST_MAX_H;
}

/* Steam parks its toasts in the bottom-right corner of the screen. */
static int in_corner(const XWindowAttributes *a)
{
    return a->x + a->width >= OUTPUT_X + OUTPUT_W - CORNER_RANGE &&
           a->y + a->height >= OUTPUT_H - CORNER_RANGE;
}

/*
 * Named like a toast -> definitely one. Otherwise fall back to its shape and
 * where Steam put it: a small override-redirect window of a Steam process,
 * parked in the screen corner. Menus, tooltips and the client's UI layers are
 * other sizes and other places.
 */
static int is_toast(Display *dpy, Window w, const XWindowAttributes *a)
{
    char *name = window_name(dpy, w);
    int match = 0;
    if (name && (strcasestr(name, "toast") || strcasestr(name, "notif")))
        match = 1;
    free(name);
    if (match)
        return 1;

    return a->override_redirect && is_toast_sized(a) && in_corner(a) &&
           pid_looks_like_steam(window_pid(dpy, w));
}

static void log_window(Display *dpy, Window w, const char *why)
{
    XWindowAttributes a;
    if (!XGetWindowAttributes(dpy, w, &a))
        return;
    char *name = window_name(dpy, w);
    char *instance = NULL, *class = NULL, *type = NULL;
    window_class(dpy, w, &instance, &class);
    type = window_type_name(dpy, w);
    logmsg("%s 0x%lx \"%s\" class=%s/%s type=%s %dx%d at %d,%d override=%d "
           "mapped=%d pid=%ld",
           why, (unsigned long)w, name ? name : "(unnamed)",
           instance ? instance : "-", class ? class : "-", type ? type : "-",
           a.width, a.height, a.x, a.y, a.override_redirect,
           a.map_state == IsViewable, window_pid(dpy, w));
    free(name);
    free(instance);
    free(class);
    if (type)
        XFree(type);
}

/* Put the toasts in the corner, newest closest to the bar, older ones stacked
 * above it. Re-pinning every tick keeps Steam from yanking them back. */
static void reposition(Display *dpy, struct toast *toasts, int *n)
{
    double t = now_s();
    int y_cursor = OUTPUT_H - BAR_H - GAP;

    for (int i = *n - 1; i >= 0; i--) {
        XWindowAttributes a;
        if (t - toasts[i].born > ENFORCE_SECONDS ||
            !XGetWindowAttributes(dpy, toasts[i].w, &a) ||
            a.map_state != IsViewable) {
            memmove(&toasts[i], &toasts[i + 1], (*n - i - 1) * sizeof toasts[0]);
            (*n)--;
            continue;
        }
        toasts[i].width = a.width;
        toasts[i].height = a.height;
        y_cursor -= toasts[i].height;
        int x = OUTPUT_X + OUTPUT_W - GAP - toasts[i].width;
        int y = y_cursor; /* OUTPUT_Y is 0, y_cursor is output-local */
        if (a.x != x || a.y != y) {
            XMoveWindow(dpy, toasts[i].w, x, y);
            logmsg("moved 0x%lx to %d,%d (%dx%d)", (unsigned long)toasts[i].w,
                   x, y, a.width, a.height);
        }
        y_cursor -= GAP;
    }
    XFlush(dpy);
}

static void track(Display *dpy, Window w, struct toast *toasts, int *n)
{
    for (int i = 0; i < *n; i++)
        if (toasts[i].w == w)
            return;

    XWindowAttributes a;
    if (!XGetWindowAttributes(dpy, w, &a) || !is_toast(dpy, w, &a))
        return;

    if (*n == MAX_TOASTS) {
        memmove(&toasts[0], &toasts[1], (MAX_TOASTS - 1) * sizeof toasts[0]);
        (*n)--;
    }
    toasts[*n].w = w;
    toasts[*n].width = a.width;
    toasts[*n].height = a.height;
    toasts[*n].born = now_s();
    (*n)++;
    log_window(dpy, w, "toast   ");
}

int main(void)
{
    int lock = open("/tmp/steam-toast-place.lock", O_CREAT | O_RDWR, 0644);
    if (lock < 0 || flock(lock, LOCK_EX | LOCK_NB) != 0) {
        fprintf(stderr, "steam-toast-place: already running\n");
        return 1;
    }

    logf = fopen("/tmp/steam-toast-place.log", "a");
    if (!logf)
        logf = stderr;

    Display *dpy = XOpenDisplay(NULL);
    if (!dpy) {
        logmsg("cannot open display %s", getenv("DISPLAY") ?: "(unset)");
        return 1;
    }
    Window root = DefaultRootWindow(dpy);
    XSelectInput(dpy, root, SubstructureNotifyMask);

    struct toast toasts[MAX_TOASTS];
    int n = 0;

    logmsg("--- started, watching %s ---", getenv("DISPLAY") ?: "?");

    /* Toasts can already be on screen when we start. */
    {
        Window root_ret, parent, *children = NULL;
        unsigned int nchildren = 0;
        if (XQueryTree(dpy, root, &root_ret, &parent, &children, &nchildren)) {
            for (unsigned int i = 0; i < nchildren; i++) {
                log_window(dpy, children[i], "toplevel");
                track(dpy, children[i], toasts, &n);
            }
            if (children)
                XFree(children);
        }
    }

    int xfd = ConnectionNumber(dpy);
    for (;;) {
        while (XPending(dpy)) {
            XEvent ev;
            XNextEvent(dpy, &ev);
            /* xany.window is the *parent* for these events: use the typed
             * fields, each of which names the window the event is about. */
            switch (ev.type) {
            case CreateNotify:
                log_window(dpy, ev.xcreatewindow.window, "seen    ");
                track(dpy, ev.xcreatewindow.window, toasts, &n);
                break;
            case MapNotify:
                log_window(dpy, ev.xmap.window, "seen    ");
                track(dpy, ev.xmap.window, toasts, &n);
                break;
            case ConfigureNotify:
                log_window(dpy, ev.xconfigure.window, "seen    ");
                track(dpy, ev.xconfigure.window, toasts, &n);
                break;
            case UnmapNotify:
            case DestroyNotify: {
                Window w = (ev.type == UnmapNotify) ? ev.xunmap.window
                                                    : ev.xdestroywindow.window;
                for (int i = 0; i < n; i++)
                    if (toasts[i].w == w) {
                        logmsg("gone    0x%lx", (unsigned long)w);
                        memmove(&toasts[i], &toasts[i + 1],
                                (n - i - 1) * sizeof toasts[0]);
                        n--;
                        break;
                    }
                break;
            }
            }
        }

        reposition(dpy, toasts, &n);

        fd_set fds;
        FD_ZERO(&fds);
        FD_SET(xfd, &fds);
        struct timeval tv = { (long)TICK_SECONDS,
                              (long)((TICK_SECONDS - (long)TICK_SECONDS) * 1e6) };
        if (select(xfd + 1, &fds, NULL, NULL, &tv) < 0 && errno != EINTR) {
            logmsg("select failed: %s", strerror(errno));
            break;
        }
    }

    XCloseDisplay(dpy);
    return 0;
}
