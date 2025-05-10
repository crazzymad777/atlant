module atlant.filesystem.utils;

import atlant.utils.string;

int getMime(String* s1, char* filename)
{
    import core.sys.posix.unistd;
    int[2] pipefd;
    if (pipe(pipefd) == 0)
    {
        int pid = fork();
        if (pid > 0)
        {
            char buf;
            long i = read(pipefd[0], &buf, 1);
            while (i > 0)
            {
                import core.stdc.stdio;
                if (buf == '\n') break;
                int j = s1.put(buf, 32);
                i = read(pipefd[0], &buf, 1);
            }
            close(pipefd[0]);
            return 0;
        }
        else if (pid == 0)
        {
            import core.sys.posix.fcntl;
            import core.stdc.stdio;

            // redirect stdout of Child
            close(STDOUT_FILENO);
            fcntl(pipefd[1], F_DUPFD, STDOUT_FILENO);
            execlp("file".ptr, "file".ptr, "-ibL".ptr, filename, null);
            // if it was success then code not reached
            perror("execlp failed");
        }
        else
        {
            import core.stdc.stdio;
            perror("fork failed");
        }
    }
    return -1;
}
