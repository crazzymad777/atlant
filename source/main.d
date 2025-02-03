import atlant.hash_table;
import atlant.scanner;
import atlant.gem;

import vibe.vibe;

HashTable gold;

void main(string[] args)
{
	import atlant.utils.configuration;
	import std.conv: to;

	auto conf = defaultConfiguration();
	parseArgs(&conf, args); // break when --help passed

	Scanner scanner = new Scanner();
	scanner.configure(conf);
	scanner.scan();
	gold = scanner.build(conf.lazyLoad);
	auto listener = listenHTTP(":" ~ to!string(conf.port), &handleRequest);
	scope (exit) listener.stopListening();
	runEventLoop();
}

void handleRequest(HTTPServerRequest req, HTTPServerResponse res)
{
	auto gem = gold.search(req.requestURI);
	if (gem !is null)
	{
		if (!gem.payload.dirty)
		{
			if (gem.payload.loaded)
			{
				res.writeBody(cast(ubyte[]) gem.payload.data, gem.payload.mime);
				return;
			}

			gem.load();
			// we need to check dirty flag
			if (!gem.payload.dirty)
			{
				res.writeBody(cast(ubyte[]) gem.payload.data, gem.payload.mime);
			}
		}
	}
}

