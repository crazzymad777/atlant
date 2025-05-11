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
            import core.sys.posix.sys.wait;

            int status = 0;
            wait(&status);
            if (status == 0)
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

            close(pipefd[0]);
            close(pipefd[1]);
        }
        else if (pid == 0)
        {
            import core.sys.posix.fcntl;
            import core.stdc.stdlib;
            import core.stdc.stdio;

            // redirect stdout of Child
            close(STDOUT_FILENO);
            fcntl(pipefd[1], F_DUPFD, STDOUT_FILENO);
            execlp("file".ptr, "file".ptr, "-ibL".ptr, filename, null);
            // if it was success then code not reached
            perror("execlp failed");
            exit(-1);
        }
        else
        {
            import core.stdc.stdio;
            perror("fork failed");
        }
    }
    return -1;
}

int readFile(String* s1, char** data, size_t* length)
{
    import core.stdc.stdlib;
    import core.stdc.stdio;
    FILE* fp = fopen(s1.data, "r");
    if (fp !is null)
    {
        fseek(fp, 0, SEEK_END);
        *length = ftell(fp);
        *data = cast(char*) malloc(*length);
        fseek(fp, 0, SEEK_SET);
        fread(*data, *length, 1, fp);
        fclose(fp);
        return 0;
    }
    return -1;
}

