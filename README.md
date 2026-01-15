# IMPORTANT

Forked apnadkarni's great work to make Tk see system fonts. **Only 64-bit Tcl 9 builds for Linux here**, since for Windows the amazing [Magicsplat's Tcl/Tk 9 installer](https://www.magicsplat.com/tcl-installer/) is available, and I highly recommend it. As for Mac, you can try MacPorts, maybe they have Tcl/Tk 9 available.

- [Here's the original repo](https://github.com/apnadkarni/tcl-builds)
- [Here are my releases](https://github.com/serpinio/tcl-builds-with-libxft/releases)

Experimental batteries-included build of Tcl 9.0.3 for Linux compiled with Xft Support. Created out of curiosity more than anything else, because I wanted a batteries included Tcl/Tk 9 package to play with on Linux. It works!

Successfully tested in Linux Mint 22.2 MATE:
- Tk with smooth font rendering

<img width="422" height="436" alt="image" src="https://github.com/user-attachments/assets/846bbeba-36ea-4940-a60d-956a3b12dde8" />

- tls socket/https connections* _(*see instructions below)_
- http library and localhost in/out connections
- sqlite (basic tests)

## "Installation"

1. Extract it to a folder in your home directory, e.g., `~/tcl9`
2. Add the binaries and libraries to your shell path. Open your `.bashrc`: `nano ~/.bashrc` and Add this at the end:

```
# Tcl 9 Environment
export TCL_ROOT=$HOME/tcl9
export PATH="$TCL_ROOT/bin:$PATH"
export LD_LIBRARY_PATH="$TCL_ROOT/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
# Aliases for convenience
alias tclsh='tclsh9.0'
alias wish='wish9.0'
```

4. Run: `source ~/.bashrc`
5. Check by running `tclsh` or `wish` in the Terminal. Type `info patchlevel` — it should return "9.0.3"

## Configure Linux linker

To make `LD_LIBRARY_PATH` discoverable when running .tcl scripts not from an already open terminal, but also via a file manager (which usually doesn't read `.bashrc` upon spawning the terminal for `-x` executable files), we need to let the Linux linker (ld) know about the new `tcl9` folder globally:

1. Create a new config file: `sudo nano /etc/ld.so.conf.d/tcl9.conf`
2. Paste the path to your lib folder: `/home/mint/tcl9/lib`
3. Save and run: `sudo ldconfig`

From this moment on, you should be able to run tcl scripts via anything that spawns a clean terminal which doesn't set up environment vars specified in `.bashrc`. If you **don't** do this, you'll be getting this error:

`/home/username/tcl9/bin/wish9.0: error while loading shared libraries: libtcl9tk9.0.so: cannot open shared object file: No such file or directory `

## How to fix "socket errors" with HTTPS connections

Again, since this is a portable distribution, the `tls` package also needs to be told where your Linux OS stores its Root Certificates (Trust Store). Place this snippet at the top of any script making `https` requests:

```
# --- Dependencies ---
package require http
package require tls

# List of common CA bundle locations on different Linux distros
set ca_bundles {
    "/etc/ssl/certs/ca-certificates.crt" 
    "/etc/pki/tls/certs/ca-bundle.crt"
    "/etc/ssl/ca-bundle.pem"
}

set found_ca 0
foreach path $ca_bundles {
    if {[file exists $path]} {
        http::register https 443 [list ::tls::socket -autoservername 1 -cafile $path]
        set found_ca 1
        break
    }
}

# Fallback: if no system bundle is found, try registering without explicit path
if {!$found_ca} {
    http::register https 443 [list ::tls::socket -autoservername 1]
}
```

Copyright and everything belong to the author of the original repo and Tcl/Tk/library developers.
