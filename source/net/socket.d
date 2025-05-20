module atlant.net.socket;

import core.sys.posix.sys.socket: sockaddr;
int create(int af, sockaddr* servaddr, uint servaddrlen)
{
    import core.sys.posix.sys.socket;
    import core.stdc.stdio;
    int sockfd = socket(af, SOCK_STREAM, 0);
    if (sockfd == -1)
    {
        perror("socket");
        return -1;
    }

    int v = 1;
    setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &v, int.sizeof);
    setsockopt(sockfd, SOL_SOCKET, SO_REUSEPORT, &v, int.sizeof);

    if (bind(sockfd, servaddr, servaddrlen) != 0)
    {
        perror("bind");
        return -1;
    }

    if ((listen(sockfd, 0)) != 0)
    {
        perror("listen");
        return -1;
    }
    return sockfd;
}
