# What This Is

Experimental Tcl/Tk 9.x "Batteries Included" Linux builds with access to system fonts (xft) based on Paul Obermeier's [BAWT](https://www.tcl3d.org/bawt/) framework.

Available architectures in [Releases](https://github.com/cgicoffee/tcl-builds-with-libxft/releases):

- x86_64 (built in Ubuntu 22.04-x64)
- ARM64 (built in Ubuntu 22.04-arm)

**Only 64-bit Tcl 9 builds for Linux here**. As for other platforms:

- For Windows the amazing [Magicsplat's Tcl/Tk 9](https://www.magicsplat.com/tcl-installer/) is available
- For macOS [refer to the original repo](https://github.com/apnadkarni/tcl-builds/releases) or [use Homebrew](https://formulae.brew.sh/formula/tcl-tk)

## Contents

1. [User-Space Installation](#user-space-installation)
2. [System-Wise Installation](#system-wise-installation)
3. [Tips And Tricks](#tips-and-tricks)
4. [Included Modules](#included-modules)

## Description

Experimental batteries-included build of Tcl 9.0.3 for Linux compiled with Xft Support for smooth font rendering, meant to be used in distros that either still distribute Tcl/Tk **8.6** or lack tcl packages in repos.

<img width="422" height="436" alt="image" src="https://github.com/user-attachments/assets/846bbeba-36ea-4940-a60d-956a3b12dde8" />

## User-Space Installation 

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

6. Finally, configure Linux Linker. To make `LD_LIBRARY_PATH` discoverable when running .tcl scripts not from an already open terminal, but also via a file manager (which usually doesn't read `.bashrc` upon spawning the terminal for `-x` executable files), you need to let the Linux linker know about the new `tcl9` folder globally:
   1. Create a new config file: `sudo nano /etc/ld.so.conf.d/tcl9.conf`
   2. Paste the path to your lib folder (replace "username" with yours): `/home/username/tcl9/lib`
   3. Save and run: `sudo ldconfig`

From this moment on, you should be able to run tcl scripts via anything that spawns a clean terminal which doesn't set up environment vars specified in `.bashrc`. If you **don't** do this, you'll be getting this error:

`/home/username/tcl9/bin/wish9.0: error while loading shared libraries: libtcl9tk9.0.so: cannot open shared object file: No such file or directory `

## System-Wise Installation

If you know what you're doing and want to install Tcl/Tk 9 system-wise, for all users, do the following.

1. Download a distribution ZIP for your architecture from [Releases](https://github.com/serpinio/tcl-builds-with-libxft/releases) and put it into `~/Downloads`
2. Run the following commands to unzip the package to `/opt/` and configure it:

```bash
# Create the directory
sudo mkdir -p /opt/tcl9
# Extract your zip. Make sure to update the name of the zip file below!
sudo unzip ~/Downloads/TclTk_9.0.3_BI_xft_v1.1_linux_arm64.zip -d /opt/tcl9
# Ensure root owns the files but everyone can read/execute
sudo chown -R root:root /opt/tcl9
sudo chmod -R 755 /opt/tcl9cd /opt/tcl9/lib
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
# Run ldconfig again
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

# PASTE THIS BLOCK INTO THE FILE:

# Tcl 9 Global Environment
export TCL_ROOT=/opt/tcl9
export PATH="$TCL_ROOT/bin:$PATH"
# Set Tcl Library path for the interpreter to find packages
export TCLLIBPATH="/opt/tcl9/lib $TCLLIBPATH"
# Aliases for interactive shells
alias tclsh='tclsh9.0'
alias wish='wish9.0'
```

5. (Optional, but recommended) Create symbolic links:

```bash
sudo ln -sf /opt/tcl9/bin/tclsh9.0 /usr/local/bin/tclsh
sudo ln -sf /opt/tcl9/bin/wish9.0 /usr/local/bin/wish
```

6. **Log out of the user session, and log back in**, or reboot the OS to see the changes
7. To test, create a file `list_packages.tcl` with the following contents and execute it using `tclsh list_packages.tcl` — you should see "Tcl/Tk version: 9.0.3" and a long list of packages which are included in this distribution, confirming successful installation:

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

6. As a final test, if you're using a desktop environment with a file manager (like Caja, Nautilus, Thunar etc) — set up an association for .tcl files to execute with `tclsh` and try opening some of the files right from the file manager, to see that the environment variables and packages are picked up correctly thanks to the linker configuration done above

## Tips And Tricks

### How To Fix HTTPS "Failed To Use Socket" Errors

Since this is a "portable" distribution, the `tls` package needs to be told where *your* Linux distro stores its Root Certificates (Trust Store). Place this tls bootstraping snippet at the top of any script making `https` requests. This is a good practice overall, especially if you're planning to distribute your tcl scripts to users of all sorts of distros and want to ensure tls works right.

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


## Included Modules

```
giflib 5.2.1
JPEG 9.f
libffi 3.4.8
libwebp 1.2.4
nasm 2.16.3
openjpeg 2.5.3
openssl 3.5.4
pandoc 3.5
pkgconfig 0.29.2
SDL 2.26.2
SWIG 4.4.0
Tcl 9.0.3
tcl9migrate 1.0
Tcladdressbook 1.2.4
tclAE 2.0.7
Tclapplescript 2.2
tclargp 0.2
tclcompiler 2.0a0
tclcsv 2.4.3
tclparser 1.9
TclStubs 9.0.3
tcltls 2.0b3
tclvfs 1.5.0
tclx 9.0.0
tdom 0.9.6
Tk 9.0.3
tkcon 2.8
Tkhtml 3.0.2
tklib 0.9
tko 0.4
tkpath 0.4.2
TkStubs 9.0.3
tksvg 0.16
Tktable 2.12
tkwintrack 2.1.1
treectrl 2.5.2
trofs 0.4.9
tserialport 1.1.1
tsw 1.3
twapi 5.2.0
udp 1.0.12
ukaz 2.1
vectcl 0.2.1
vlerq 4.1
wcb 4.2
windetect 2.0.1
winhelp 1.1.1
xz 5.4.1
yasm 1.3.0
Zipkit 
ZLib 1.3.1
apave 4.4.10
argparse 0.62
awthemes 10.4.0
BWidget 1.10.1
Canvas3d 1.2.3
cffi 2.0.3
critcl 3.3
DiffUtil 0.4.3
expect 5.45.4.1
ffmpeg 7.1.3
imgtools 0.3.1
iocp 2.0.2
itk 4.2.5
iwidgets 4.1.2
materialicons 0.2
memchan 2.3.1
mentry 4.5
Mpexpr 1.2.1
mqtt 4.0
nacl 1.1.1
nsf 2.4.0
ooxml 1.10
oratcl 4.6.1
parse_args 0.5.1
pdf4tcl 0.9.4
pgintcl 3.5.2
photoresize 0.2.1
PNG 1.6.48
poImg 3.0.1
poLibs 3.2.1
poMemory 1.0.0
publisher 2.0
puppyicons 0.1
rbc 0.2.0
rl_json 0.16.0
rtext 0.1.1
ruff 2.7.0
scrollutil 2.7
shellicon 0.2.0
Snack 2.2.12
tablelist 7.8
tbcload 2.0a0
tclfpdf 1.7.3
Tclkit 
tcllib 2.1
TclTkManual 
tclws 3.5.0
thtmlview 2.0.0
TIFF 4.7.0
Tix 8.4.4
tkdnd 2.9.5
tkribbon 1.2
Freetype 2.13.3
Img 2.1.0
cawt 3.1.1
```
