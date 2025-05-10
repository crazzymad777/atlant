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
    scanner.detach(); // detach tree root
    // scanner.show();

    import atlant.cache.hash_table;
    HashTable ht = HashTable(scanner.root);
    // ht.show();
    // ht.drop();

    import atlant.http.server;
    Server server;
	server.listen(conf.port);
}

import atlant.http.session;

Response handleRequest(Request req)
{
	import atlant.utils.data;
	return Response(404, Data.fromString("Requested Resource Not Found"), "text/plain");
}
