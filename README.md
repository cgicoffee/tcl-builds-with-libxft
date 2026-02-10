# What This Is

Experimental Tcl/Tk 9.x "Batteries Included" Linux builds with access to system fonts (xft) based on Paul Obermeier's [BAWT](https://www.tcl3d.org/bawt/) framework.

Available architectures in [Releases](https://github.com/cgicoffee/tcl-builds-with-libxft/releases):

- x86_64. Built in Ubuntu 22.04-x64. Tested in Ubuntu 22.04/24.04, Linux Mint 22.2
- ARM64. Built in Ubuntu 22.04-arm. Tested in Ubuntu 24.04, OrangePi OS (Arch Linux-based, rolling)

**Only 64-bit Tcl 9 builds for Linux here**. As for other platforms:

- For Windows the amazing [Magicsplat's Tcl/Tk 9](https://www.magicsplat.com/tcl-installer/) is available
- For macOS [refer to the original repo](https://github.com/apnadkarni/tcl-builds/releases) or [use Homebrew](https://formulae.brew.sh/formula/tcl-tk)

## Contents

1. [User-Space Installation](#user-space-installation)
2. [System-Wise Installation](#system-wise-installation)

## Description

Experimental batteries-included build of Tcl 9.0.3 for Linux compiled with Xft Support for smooth font rendering, meant to be used in distros that either still distribute Tcl/Tk **8.6** or lack tcl packages in repos.

<img width="422" height="436" alt="image" src="https://github.com/user-attachments/assets/846bbeba-36ea-4940-a60d-956a3b12dde8" />

## User-Space Installation 

"Quick'n'dirty" installation, or an option for cases when no root access is available. Less versatile than a [system-wise](#system-wise-installation) deployment.

1. Extract it to a folder in your home directory, e.g., `~/tcl9`
2. Add the binaries and libraries to your shell path. Open your `.bashrc`: `nano ~/.bashrc` and Add this at the end (change the path if needed):

```bash
# Tcl 9 Environment
export TCL_ROOT=$HOME/tcl9
export PATH="$TCL_ROOT/bin:$PATH"
export LD_LIBRARY_PATH="$TCL_ROOT/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
# Aliases for convenience
alias tclsh='tclsh9.0'
alias wish='wish9.0'
```

4. Run: `source ~/.bashrc`
5. Check by running `tclsh` or `wish` in the Terminal. Type `info patchlevel` — it should return "9.0.3. **Note:** If you have another version of Tcl/Tk installed in the system, adding these environment variables will shadow all calls to "default" `tclsh` and `wish` in the console, replacing them with ones from this distribution. To revert back, simply remove this block from `~/.bashrc` and call `source ~/.bashrc`

6. Finally, _if you have root access_, make your life easier by configuring the Linux Linker. To make `LD_LIBRARY_PATH` discoverable when running .tcl scripts not from an already open terminal, but also via a file manager (which usually doesn't read `.bashrc` upon spawning the terminal for `-x` executable files), you need to let the Linux linker know about the new `tcl9` folder globally:
   1. Create a new config file: `sudo nano /etc/ld.so.conf.d/tcl9.conf`
   2. Paste the path to your lib folder (replace "username" with yours): `/home/username/tcl9/lib`
   3. Save and run: `sudo ldconfig`

From this moment on, you should be able to run tcl scripts via anything that spawns a clean terminal which doesn't set up environment vars specified in `.bashrc`. If you **don't** do this, you'll be getting this error:

`/home/username/tcl9/bin/wish9.0: error while loading shared libraries: libtcl9tk9.0.so: cannot open shared object file: No such file or directory `

### How To Fix HTTPS "Failed To Use Socket" Errors

**Important: this workaround is relevant only for the user-space installation**. System-wide install covers this with the global profile script. Still, bootstrapping tls cert paths in tcl scripts is good practice, especially if you're planning to distribute your scripts to users of all sorts of distros and want to ensure tls works right.

Since this is a "portable" distribution, the `tls` package needs to be told where *your* Linux distro stores its Root Certificates (Trust Store). Place this tls bootstraping snippet at the top of any script making `https` requests. 

```tcl
# Dependencies
package require http
package require tls

# SSL/TLS Certificate Linux Path Bootstrap
# If provided, accept the existing env variable
if {[info exists ::env(SSL_CERT_FILE)] && [file exists $::env(SSL_CERT_FILE)]} {
    http::register https 443 [list ::tls::socket -autoservername 1 -cafile $::env(SSL_CERT_FILE)]
} else {
    # Otherwise check the list of common CA bundle locations
    set ca_bundles { "/etc/ssl/certs/ca-certificates.crt" "/etc/pki/tls/certs/ca-bundle.crt" "/etc/ssl/ca-bundle.pem" }
    set found_ca 0
    foreach path $ca_bundles {
        if {[file exists $path]} {
            http::register https 443 [list ::tls::socket -autoservername 1 -cafile $path]; set found_ca 1; break
        }
    }
    # Default registration (for all OSes as well)
    if {!$found_ca} { http::register https 443 [list ::tls::socket -autoservername 1] }
    unset -nocomplain ca_bundles found_ca path
}
# --- SSL/TLS Certificate Linux Path Bootstrap ---
```

## System-Wise Installation

If you have root permissions and know what you're doing, you can install Tcl/Tk 9 _system-wise_. This is a vastly superior option, since it solves the missing ssl certs problem, as well as makes Tcl/Tk 9 available to all users by default, including all the numerous packages this distribution comes with. Th following guide has been successfully used to install this bundle in several Linux distros: Linux Mint 22.2, Ubuntu 22.04 on PC, Arch Linux-based OrangePi OS (arm64) and a Debian-based RaspberryPi OS (arm64).

1. Download a distribution ZIP for your architecture from [Releases](https://github.com/serpinio/tcl-builds-with-libxft/releases) and put it into `~/Downloads`
2. Run the following commands to unzip the package to `/opt/` and configure it:

```bash
# Create the directory
sudo mkdir -p /opt/tcl9
# Extract your zip. !!! Make sure to change the name of the zip file below!
sudo unzip ~/Downloads/TclTk_9.0.3_BI_xft_v1.1_linux_x86_64.zip -d /opt/tcl9
# Ensure root owns the files but everyone can read/execute
sudo chown -R root:root /opt/tcl9
sudo chmod -R 755 /opt/tcl9
```

3. `ldconfig` expects a specific naming convention where, for instance, a versioned shared library `libffi.so.8.1.4` has a `libffi.so.8`  symbolic link pointing to it. In case of a ZIP distribution (the one in this repo), *zipping turns that link into a regular file*, and ldconfig will complain if you try to run `sudo ldconfig` right after unpacking:  `"ldconfig: /opt/tcl9/lib/libffi.so.8 is not a symbolic link"`. To avoid this, restore the symlink with the following commands:

```bash
cd /opt/tcl9/lib
# Identify the actual library file (it's likely libffi.so.8.*.*, may change between builds)
REAL_FILE=$(ls libffi.so.8.* | head -n 1)
# Delete the face symlink which is actually a duplicate after the zipping process
sudo rm libffi.so.8
# Create a proper symbolic link
sudo ln -s "$REAL_FILE" libffi.so.8
# NOW ldconfig should succeed
sudo ldconfig
```

4. For the global linker configuration, since new binaries link to libtcl9tk9.0.so etc. inside `/opt/tcl9/lib`, the OS needs to know where to look. This replaces the need for `LD_LIBRARY_PATH` from the user-space installation option:

```bash
# Create a linker config file
echo "/opt/tcl9/lib" | sudo tee /etc/ld.so.conf.d/tcl9.conf
# Refresh the linker cache
sudo ldconfig
```

5. Finally, configure global PATH and environment for all users: 

```bash
# Create a global profile script
sudo nano /etc/profile.d/tcl9.sh
```

6. Paste these directives into the file, and save it

```
# Tcl 9 Global Environment
export TCL_ROOT=/opt/tcl9
export PATH="$TCL_ROOT/bin:$PATH"
# Set Tcl Library path for the interpreter to find packages
export TCLLIBPATH="/opt/tcl9/lib $TCLLIBPATH"
# Aliases for interactive shells
alias tclsh='tclsh9.0'
alias wish='wish9.0'

# Auto-detect and export the SSL Trust Store for Tcl and other tools
for cert in /etc/ssl/certs/ca-certificates.crt \
            /etc/pki/tls/certs/ca-bundle.crt \
            /etc/ssl/ca-bundle.pem; do
    if [ -f "$cert" ]; then
        export SSL_CERT_FILE="$cert"
        break
    fi
done
```

7. (Optional, but recommended) Create symbolic links:

```bash
sudo ln -sf /opt/tcl9/bin/tclsh9.0 /usr/local/bin/tclsh
sudo ln -sf /opt/tcl9/bin/wish9.0 /usr/local/bin/wish
```

8. **Log out of the user session, and log back in**, or reboot the OS to see the changes
9. To test, create a file `list_packages.tcl` with the following contents and execute it using `tclsh list_packages.tcl` — you should see "Tcl/Tk version: 9.0.3" and a long list of packages which are included in this distribution, confirming successful installation:

```tcl
# list_packages.tcl
puts "Tcl/Tk version: [info patchlevel]"
proc get_all_packages {} {
    # Force a search of the filesystem
    catch {package require __dummy__}    
    set pkgs [lsort -dictionary [package names]]
    puts [format "%-25s | %-10s" "PACKAGE" "VERSION"]
    puts [string repeat "-" 40]    
    foreach pkg $pkgs {
        # Some core packages are built-in, others need version querying
        set version [package provide $pkg]
        if {$version eq ""} {
            # Try to see if it's available but not loaded
            if {[catch {set version [package present $pkg]} err]} {
                set version "Available"
            }
        }
        puts [format "%-25s | %-10s" $pkg $version]
    }
}
get_all_packages
```

10. As a final test, if you're using a desktop environment with a file manager (like Caja, Nautilus, Thunar etc) — set up an association for .tcl files to execute with `tclsh` and try opening some of the files directly via the file manager, to see that the environment variables and packages are picked up correctly thanks to the linker configuration done above
