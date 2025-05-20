module atlant.net.address;

import core.sys.posix.netinet.in_: sockaddr_in6, sockaddr_in;
import atlant.utils.list;

bool parse(char* name, ushort port, sockaddr_in6* addr, bool* flag)
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
        import atlant.net.ipv6;
        normalize4to6(addr);
        *flag = true;
        // list.add(addr);
        return true;
    }

    return false;
}

// bool parse(char* name, ushort port, List!(sockaddr_in6)* list)
// {
//     import core.sys.posix.netinet.in_: sockaddr_in6, inet_pton, in6addr_any, htons;
//     import core.sys.posix.sys.socket: AF_INET6, AF_INET;
//     sockaddr_in6 addr;
//     addr.sin6_family = cast(ushort) AF_INET6;
//     addr.sin6_port = htons(port);
//
//     if (name is null)
//     {
//         addr.sin6_addr = in6addr_any;
//         list.add(addr);
//         return true;
//     }
//
//     if (inet_pton(AF_INET6, name, &addr.sin6_addr) == 1)
//     {
//         list.add(addr);
//         return true;
//     }
//
//     if (inet_pton(AF_INET, name, &addr.sin6_addr) == 1)
//     {
//         // normalize4to6(&addr);
//         list.add(addr);
//         return true;
//     }
//
//     import core.sys.posix.netdb;
//     addrinfo* addrinfo;
//     int result = getaddrinfo(name, null, null, &addrinfo);
//     auto source = addrinfo;
//
//     import core.stdc.stdio;
//     if (result == 0)
//     {
//         int hits = 0;
//         while (addrinfo !is null)
//         {
//             if (addrinfo.ai_family == AF_INET || addrinfo.ai_family == AF_INET6)
//             {
//                 import core.stdc.string: memcpy;
//                 memcpy(&addr, &addrinfo.ai_addr, addrinfo.ai_addrlen);
//                 addr.sin6_port = htons(port);
//                 list.add(addr);
//                 hits++;
//             }
//             addrinfo = addrinfo.ai_next;
//         }
//
//         freeaddrinfo(source);
//         if (hits > 0)
//         {
//             return true;
//         }
//     }
//     else
//     {
//         perror("freeaddrinfo");
//     }
//
//     return false;
// }

void map6to4(List!(sockaddr_in6)* source, List!(sockaddr_in)* dest)
{
    import core.sys.posix.sys.socket: AF_INET6, AF_INET;
    import core.stdc.string: memcpy;
    auto node = source.front();
    sockaddr_in x;
    while (node !is null)
    {
        if (node.value.sin6_family == AF_INET)
        {
            memcpy(&x, &node.value, x.sizeof);
            dest.add(x);
        }
        else if (node.value.sin6_family == AF_INET6)
        {

        }
        node = node.next;
    }
}
