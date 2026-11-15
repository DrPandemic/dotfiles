//@ pragma Env QT_QUICK_BACKEND=software
//@ pragma UseQApplication

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
