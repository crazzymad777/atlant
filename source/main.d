import atlant.hash_table;
import atlant.scanner;
import atlant.gem;

import vibe.vibe;

string workingDirectory;
HashTable gold;

void main()
{
	import std.process: environment;
	import std.file: getcwd;
	Scanner scanner = new Scanner();

	auto directory = environment.get("ATLANT_OVERRIDE_DIRECTORY");
	if (directory is null)
	{
		directory = getcwd();
	}

	workingDirectory = directory;
	scanner.setDirectory(directory);
	scanner.scan();

	gold = scanner.build();

	auto port = environment.get("ATLANT_HTTP_PORT", "80");

	auto listener = listenHTTP(":" ~ port, &handleRequest);
	scope (exit) listener.stopListening();

	runApplication();
}

void handleRequest(HTTPServerRequest req, HTTPServerResponse res)
{
	auto gem = gold.search(req.requestURI);
	if (gem !is null)
	{
		if (gem.data != null)
		{
			res.writeBody(cast(ubyte[]) gem.data, gem.mime);
		}
	}
}

