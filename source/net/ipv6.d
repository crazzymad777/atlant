module atlant.net.ipv6;

import core.sys.posix.netinet.in_;
void normalize(bool anyaddr, int family, sockaddr_in6* addr, bool translated)
{
    // import core.sys.posix.netinet.in_;
    import core.sys.posix.sys.socket;
    if (anyaddr || translated)
    {
        if (family == AF_INET6 || translated)
        {
            if (addr.sin6_addr.s6_addr[0x0a] == 0xff &&
                addr.sin6_addr.s6_addr[0x0b] == 0xff)
            {
                int hits = 0;
                for (; hits  < 0xa; hits ++)
                {
                    if (addr.sin6_addr.s6_addr[hits ] != 0)
                    {
                        break;
                    }
                }

                if (hits == 0xa)
                {
                    // That's IPv4 address mapped to IPv6
                    // Translation
                    addr.sin6_family = AF_INET;
                    addr.sin6_addr.s6_addr[0x00] = addr.sin6_addr.s6_addr[0x0c];
                    addr.sin6_addr.s6_addr[0x01] = addr.sin6_addr.s6_addr[0x0d];
                    addr.sin6_addr.s6_addr[0x02] = addr.sin6_addr.s6_addr[0x0e];
                    addr.sin6_addr.s6_addr[0x03] = addr.sin6_addr.s6_addr[0x0f];

                    for (int i = 0x0a; i <= 0x0f; i++)
                    {
                        addr.sin6_addr.s6_addr[i] = 0x0;
                    }
                }
            }
        }
    }
}

void normalize4to6(sockaddr_in6* addr)
{
    addr.sin6_family = AF_INET6;
    addr.sin6_addr.s6_addr[0x0a] = 0xff;
    addr.sin6_addr.s6_addr[0x0b] = 0xff;

    addr.sin6_addr.s6_addr[0x0c] = addr.sin6_addr.s6_addr[0x00];
    addr.sin6_addr.s6_addr[0x0d] = addr.sin6_addr.s6_addr[0x01];
    addr.sin6_addr.s6_addr[0x0e] = addr.sin6_addr.s6_addr[0x02];
    addr.sin6_addr.s6_addr[0x0f] = addr.sin6_addr.s6_addr[0x03];

    for (int i = 0x00; i < 0x0a; i++)
    {
        addr.sin6_addr.s6_addr[i] = 0x0;
    }
}
