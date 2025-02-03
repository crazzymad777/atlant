module atlant.utils.configuration;

struct Configuration
{
    string workingDirectory;
    bool enableDirectoryList; // bool showDirectoryContents;
    bool lazyLoad;
    int port; // bind addresses...
}

private bool parseBool(string flag, bool def)
{
    import std.uni: toLower;
    flag = toLower(flag);
    if (flag == "1" || flag == "y" || flag == "true" || flag == "yes" || flag == "t")
	{
		return true;
	}

	if (flag == "0" || flag == "n" || flag == "false" || flag == "no" || flag == "f")
	{
		return false;
	}
    return def;
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
    conf.enableDirectoryList = parseBool(environment.get("ATLANT_ENABLE_DIRECTORY_LIST"), false);

	// Non-cannonical mode
	conf.lazyLoad = parseBool(environment.get("ATLANT_LAZY_LOAD"), false);

	string strPort = environment.get("ATLANT_HTTP_PORT", "80");
    conf.port = parse!int(strPort);
    return conf;
}

void parseArgs(Configuration* conf, string[] args)
{
    enum Option
    {
        None,
        WorkingDirectory,
        Option
    };

    Option next = Option.None;
    bool nextValue = false;
    import core.stdc.stdlib: exit;
    for (int i = 1; i < args.length; i++)
    {
        if (nextValue)
        {
            if (next == Option.WorkingDirectory)
            {
                conf.workingDirectory = args[i];
            }
            else if (next == Option.Option)
            {

            }

            next = Option.None;
            nextValue = false;
            continue;
        }

        if (args[i] == "--help" || args[i] == "-h")
        {
            exit(0);
        }

        if (args[i] == "-l" || args[i] == "--lazy")
        {
            conf.lazyLoad = true;
        }

        if (args[i] == "-w" || args[i] == "--working-directory")
        {
            nextValue = true;
            next = Option.WorkingDirectory;
        }

        if (args[i] == "-o" || args[i] == "--option")
        {
            nextValue = true;
            next = Option.Option;
        }
    }
}
