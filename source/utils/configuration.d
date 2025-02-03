module atlant.utils.configuration;

struct Configuration
{
    string workingDirectory;
    bool enableDirectoryList; // bool showDirectoryContents;
    bool lazyLoad;
    int port; // bind addresses...
}

Configuration defaultConfiguration()
{
    import std.process: environment;
	import std.file: getcwd;
	import std.conv;
    Configuration conf;
    conf.workingDirectory = environment.get("ATLANT_OVERRIDE_DIRECTORY");
	if (conf.workingDirectory is null)
	{
		conf.workingDirectory = getcwd();
	}

	conf.enableDirectoryList = false;
	string valueEnableDirectoryList = environment.get("ATLANT_ENABLE_DIRECTORY_LIST");
	if (valueEnableDirectoryList == "1" || valueEnableDirectoryList == "y" || valueEnableDirectoryList == "true" || valueEnableDirectoryList == "yes")
	{
		conf.enableDirectoryList = true;
	}

	// Non-cannonical mode
	conf.lazyLoad = false;
	string valueLazyLoad = environment.get("ATLANT_LAZY_LOAD");
	if (valueLazyLoad == "1" || valueLazyLoad == "y" || valueLazyLoad == "true" || valueLazyLoad == "yes")
	{
		conf.lazyLoad = true;
	}

	string strPort = environment.get("ATLANT_HTTP_PORT", "80");
    conf.port = parse!int(strPort);
    return conf;
}

void parseArgs(Configuration* conf, string[] args)
{

}
