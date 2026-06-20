# Aurora imports exactly this file for custom ujust recipes (see 00-entry.just,
# which only does `import? ".../60-custom.just"` — it does NOT glob *.just).
# Keep appsync encapsulated in its own file and pull it in here. Add further
# custom-recipe files the same way, or define recipes directly below.

import "/usr/share/ublue-os/just/90-appsync.just"
