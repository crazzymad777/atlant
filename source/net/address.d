module atlant.net.address;

import core.sys.posix.netinet.in_: sockaddr_in6, sockaddr_in;
import atlant.utils.list;

bool parse(char* name, ushort port, sockaddr_in6* addr)
{
    import core.sys.posix.netinet.in_: sockaddr_in6, inet_pton, in6addr_any, htons;
    import core.sys.posix.sys.socket: AF_INET6, AF_INET;
    // sockaddr_in6 addr;
    addr.sin6_family = cast(ushort) AF_INET6;
    addr.sin6_port = htons(port);

    if (name is null)
    {
        addr.sin6_addr = in6addr_any;
        // list.add(addr);
        return true;
    }

    if (inet_pton(AF_INET6, name, &addr.sin6_addr) == 1)
    {
        // list.add(addr);
        return true;
    }

    if (inet_pton(AF_INET, name, &addr.sin6_addr) == 1)
    {
        // import atlant.net.ipv6;
        // normalize4to6(addr);
        // *flag = true;
        // list.add(addr);
        addr.sin6_family = AF_INET;
        return true;
    }

    return false;
}

