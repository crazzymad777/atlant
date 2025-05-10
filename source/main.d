module atlant.main;

import atlant.cache.hash_table;
HashTable ht;
string bodyNotFound = "Requested Resource Not Found";
Gem notFound;

extern(C) void main()
{
    notFound = Gem(null, String.staticCString(cast(char*) "text/plain".ptr), -1, true, cast(char*) bodyNotFound.ptr, bodyNotFound.length);

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

    ht = HashTable(scanner.root);
    // ht.show();
    // ht.drop();

    import atlant.http.server;
    Server server;
	server.listen(conf.port);
}

import atlant.utils.string;
import atlant.http.session;
import atlant.cache.gem;

Response handleRequest(Request req)
{
    //import atlant.utils.string;
	import atlant.utils.data;
	return Response(404, &notFound);
}
