module atlant.main;

extern(C) void main()
{
    import atlant.utils.configuration;
    import atlant.filesystem.scanner;
    import core.stdc.stdio;

    Configuration conf;
    defaultConfiguration(&conf);
    // parseArgs...
    printf("directory=%s\n", conf.directory.data);
    printf("port=%d\n", conf.port);

    Scanner scanner = Scanner(conf.directory.data);
    scanner.scan();
    scanner.show();

    import atlant.cache.hash_table;
    HashTable ht = HashTable(scanner.root);
}
