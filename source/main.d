module atlant.main;

extern(C) void main()
{
    import atlant.utils.configuration;
    import core.stdc.stdio;

    Configuration conf;
    defaultConfiguration(&conf);
    // parseArgs...
    printf("directory=%s\n", conf.directory.data);
    printf("port=%d\n", conf.port);
}
