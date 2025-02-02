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
	// scanner.process();
	gold = new HashTable(scanner.getCounter(), scanner.getGems());
	// gold.kovalskiAnalyze();

	auto port = environment.get("ATLANT_HTTP_PORT", "80");
	listenHTTP(":" ~ port, &handleRequest);
	runApplication();
}

void handleRequest(HTTPServerRequest req, HTTPServerResponse res)
{
	auto gem = gold.search(req.path);
	if (gem !is null)
	{
		res.writeBody(cast(ubyte[]) gem.data, gem.mime);
	}
}

