//@ pragma Env QT_QUICK_BACKEND=software

import Quickshell
import Quickshell.Services.Pipewire

ShellRoot {
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Variants {
        model: Quickshell.screens

        Bar {}
    }
}
