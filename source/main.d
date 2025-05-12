module atlant.main;

import atlant.cache.hash_table;
HashTable ht;

extern(C) void main(int argc, char** argv)
{
    import core.stdc.stdio;
    import atlant.utils.configuration;
    import atlant.filesystem.scanner;

    Configuration conf;
    defaultConfiguration(&conf);
    parseArgs(&conf, argc, argv);

    Scanner scanner = Scanner(conf.directory.data);
    if (scanner.scan() == 0)
    {
        scanner.detach(); // detach tree root

        ht = HashTable(scanner.root);

        import atlant.http.server;
        Server server;
        server.listen(conf.port);
        return;
    }
}

import atlant.utils.string;
import atlant.http.session;
import atlant.cache.gem;

void handleRequest(Request req, Response* res)
{
    import atlant.utils.data;
    import core.stdc.stdio;

    String s2;
    decodeURI(&req.s1, &s2);
	auto gem = ht.getGem(&s2);

	if (gem !is null)
	{
        *res = Response(200, Response.ResultType.gem, gem: gem);
        s2.drop();
        return;
	}

	snprintf(cast(char*) res.text, 256, "Requested Resource /%s Not Found", s2.data);
	res.type = Response.ResultType.text;
	res.status = 404;
	s2.drop();
	return;
}
