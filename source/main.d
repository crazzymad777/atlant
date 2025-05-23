module atlant.main;

import atlant.cache.hash_table;
import atlant: ht;

extern(C) void main(int argc, char** argv)
{
    import core.stdc.stdio;
    import atlant.utils.configuration;
    import atlant.filesystem.scanner;
    import atlant: pidfile, openlog, closelog;

    Configuration conf;
    defaultConfiguration(&conf);
    parseArgs(&conf, argc, argv);

    debug import core.sys.posix.unistd: getpid;
    debug if (conf.logpid) printf("%d: exec\n", getpid());

    pidfile(conf.pidfile);
    openlog(conf.accesslog);

    Scanner scanner = Scanner(&conf, conf.directory.data);
    if (scanner.scan() == 0)
    {
        scanner.detach(); // detach tree root

        ht = HashTable(scanner.root);

        import atlant.http.server;
        Server server;
        server.listen(&conf);
        closelog();

        debug if (conf.logpid) printf("%d: exit\n", getpid());
        return;
    }
    closelog();

    debug if (conf.logpid) printf("%d: exit\n", getpid());
    return;
}
