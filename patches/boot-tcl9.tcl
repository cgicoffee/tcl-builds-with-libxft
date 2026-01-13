proc tclInit {} {
    rename tclInit {}

    global auto_path tcl_library tcl_libPath tcl_version tk_library

    # Tcl 9 default ZipFS mount points
    set vfs_root "//zipfs:/app"
    if {![file isdirectory $vfs_root]} {
        set vfs_root "//zipfs:/lib"
    }

    # Resolve Tcl script library path within VFS
    set tcl_library [file join $vfs_root tcl_library]
    if {![file exists [file join $tcl_library init.tcl]]} {
        set tcl_library [file join $vfs_root tcl$tcl_version]
    }

    # Set library search paths to prioritize VFS over physical filesystem
    set tcl_libPath [list $tcl_library [file join $vfs_root lib]]
    set auto_path $tcl_libPath

    # TIP 258 encoding path configuration
    set enc_dir [file join $tcl_library encoding]
    if {[file isdirectory $enc_dir]} {
        encoding dirs [list $enc_dir]
    }

    # Source primary initialization script
    if {[file exists [file join $tcl_library init.tcl]]} {
        uplevel #0 [list source [file join $tcl_library init.tcl]]
    } else {
        error "initialization failed: init.tcl not found in $tcl_library"
    }

    # Resolve and export tk_library for widget demos and themed scripts
    set tk_lib [file join $vfs_root tk_library]
    if {![file isdirectory $tk_lib]} {
        set tk_lib [file join $vfs_root tk$tcl_version]
    }
    
    if {[file isdirectory $tk_lib]} {
        set tk_library $tk_lib
        lappend auto_path $tk_lib
    }
}
