module atlant.filesystem.scanner;

import core.sys.posix.dirent;
extern(C) int dirfd(DIR *dirp);

struct Scanner
{
    this(char* directory)
    {
        this.directory = directory;
    }
    char* directory;

    void scan(char* directory = null)
    {
        import core.stdc.stdio;

        if (directory is null)
        {
            directory = this.directory;
        }

        DIR* dirptr = opendir(directory);

        if (!dirptr)
        {
            perror(directory);
            return;
        }

        traverse(dirptr);
        closedir(dirptr);
    }

    void traverse(DIR* dirptr)
    {
        import core.sys.posix.unistd;
        import core.stdc.string;
        import core.stdc.stdio;
        dirent* entry;
        while ((entry = readdir(dirptr)) !is null)
        {
            if (strcmp("..", &entry.d_name[0]) == 0)
            {
                continue;
            }

            if (strcmp(".", &entry.d_name[0]) == 0)
            {
                continue;
            }

            if (entry.d_type == DT_UNKNOWN)
            {
                // WE should determine file type
            }

            if (entry.d_type == DT_REG)
            {
                printf("f %s\n", &entry.d_name[0]);
            }

            if (entry.d_type == DT_DIR)
            {
                int fd = dirfd(dirptr);
                printf("d %s\n", &entry.d_name[0]);
                chdir(&entry.d_name[0]);
                scan(cast(char*) ".".ptr);
                fchdir(fd);
            }

            if (entry.d_type == DT_LNK)
            {
                printf("l %s\n", &entry.d_name[0]);
            }
        }
    }
}
