import atlant.hash_table;
import atlant.scanner;
import atlant.gem;

import vibe.vibe;

HashTable gold;
bool treeTraversed = false;

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

	bool enableDirectoryList = false;
	string valueEnableDirectoryList = toLower(environment.get("ATLANT_ENABLE_DIRECTORY_LIST"));
	if (valueEnableDirectoryList == "1" || valueEnableDirectoryList == "y" || valueEnableDirectoryList == "true" || valueEnableDirectoryList == "yes")
	{
		enableDirectoryList = true;
	}

	// Non-cannonical mode
	bool lazyLoad = false;
	string valueLazyLoad = toLower(environment.get("ATLANT_LAZY_LOAD"));
	if (valueLazyLoad == "1" || valueLazyLoad == "y" || valueLazyLoad == "true" || valueLazyLoad == "yes")
	{
		lazyLoad = true;
	}

	// Traverse Tree
	bool traverseTree = true;
	string valueTraverseTree = toLower(environment.get("ATLANT_TRAVERSE_TREE"));
	if (valueTraverseTree == "0" || valueTraverseTree == "n" || valueTraverseTree == "false" || valueTraverseTree == "no")
	{
		traverseTree = false;
	}

	scanner.setTraverseTreeFlag(traverseTree);
	scanner.setDirectoryList(enableDirectoryList);
	scanner.setDirectory(directory);
	scanner.scan();
	treeTraversed = traverseTree;

	gold = scanner.build(lazyLoad);

	auto port = environment.get("ATLANT_HTTP_PORT", "80");

	HTTPListener listener;
	if (treeTraversed)
	{
		listener = listenHTTP(":" ~ port, &handleReadyResource);
	}
	else
	{
		listener = listenHTTP(":" ~ port, &handleRequest);
	}
	scope (exit) listener.stopListening();

	runApplication();
}

void handleReadyResource(HTTPServerRequest req, HTTPServerResponse res)
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

void handleRequest(HTTPServerRequest req, HTTPServerResponse res)
{
	import std.array: split;
	auto parts = split(req.requestURI, '/')[1 .. $];
	string x = "";
	foreach (y; parts)
	{
		x ~= y;
		x ~= "$";
	}
	res.writeBody(x);
}

