module atlant.main;

import atlant.hash_table;
import atlant.scanner;
import atlant.gem;

__gshared HashTable gold;

void main(string[] args)
{
	import core.sys.posix.unistd;
	import core.stdc.stdio;
	printf("Server's job (%d) had started.\n", getpid());

	import atlant.utils.configuration;
	import atlant.http.server;

	auto conf = defaultConfiguration();
	parseArgs(&conf, args); // break when --help passed

	Scanner scanner = Scanner();
	scanner.configure(conf);
	scanner.scan();
	gemConf = &conf; // workaround index files
	gold = scanner.build(conf.lazyLoad);

	Server server;
	server.listen(conf.port);

	printf("Server's job (%d) had finished.\n", getpid());
}

import atlant.http.parser;

Response handleRequest(Request req)
{
	import std.string;
	import core.stdc.stdio;
	auto gem = gold.search(req.path);
	if (gem !is null)
	{
		if (!gem.payload.dirty)
		{
			if (gem.payload.loaded)
			{
				return Response(200, cast(ubyte[]) gem.payload.data, gem.payload.mime);
			}

			gem.load();
			// we need to check dirty flag
			if (!gem.payload.dirty)
			{
				return Response(200, cast(ubyte[]) gem.payload.data, gem.payload.mime);
			}
		}
	}
	return Response(404, cast(ubyte[]) ("Requested Resource Not Found"), "text/plain");
}

