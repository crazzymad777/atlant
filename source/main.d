import atlant.hash_table;
import atlant.scanner;
import atlant.gem;

HashTable gold;

void main(string[] args)
{
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
	server.listen();

	import core.stdc.stdio;
	printf("Server successfully had finished.\n");
/+
	HTTPServerSettings settings = new HTTPServerSettings();
	settings.serverString = "atlant/0.0.1-alpha";
	settings.disableDistHost = true;
	settings.bindAddresses = conf.bindAddresses;
	settings.port = cast(ushort) conf.port;

	auto listener = listenHTTP(settings , &handleRequest);
	scope (exit) listener.stopListening();
	runEventLoop();
+/
}

import atlant.http.parser;

Response handleRequest(Request req)
{
	import std.uri;
	auto gem = gold.search(decode(req.path));
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
	return Response(404, [], "text/plain");
}

