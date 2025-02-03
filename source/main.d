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
	setGlobalConfiguration(conf);

	Scanner scanner = new Scanner();
	scanner.configure(conf);
	scanner.scan();
	gold = scanner.build(conf.lazyLoad);

	HTTPServerSettings settings = new HTTPServerSettings();
	settings.serverString = "atlant/0.0.1-alpha";
	settings.disableDistHost = true;
	settings.bindAddresses = conf.bindAddresses;
	settings.port = cast(ushort) conf.port;

	auto listener = listenHTTP(settings , &handleRequest);
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

