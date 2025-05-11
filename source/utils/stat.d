module atlant.utils.stat;

public import core.sys.posix.sys.stat;

bool S_ISTYPE(mode_t mode, uint mask)
{
    return (mode & S_IFMT) == mask;
}

bool S_ISBLK( mode_t mode )  { return S_ISTYPE( mode, S_IFBLK );  }
bool S_ISCHR( mode_t mode )  { return S_ISTYPE( mode, S_IFCHR );  }
bool S_ISDIR( mode_t mode )  { return S_ISTYPE( mode, S_IFDIR );  }
bool S_ISFIFO( mode_t mode ) { return S_ISTYPE( mode, S_IFIFO );  }
bool S_ISREG( mode_t mode )  { return S_ISTYPE( mode, S_IFREG );  }
bool S_ISLNK( mode_t mode )  { return S_ISTYPE( mode, S_IFLNK );  }
bool S_ISSOCK( mode_t mode ) { return S_ISTYPE( mode, S_IFSOCK ); }
