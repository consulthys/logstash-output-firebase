# Logstash Plugin

This is an output plugin for [Logstash](https://github.com/elastic/logstash).

It is fully free and fully open source. The license is Apache 2.0, meaning you are pretty much free to use it however you want in whatever way.

## Documentation

The [Firebase](https://firebase.google.com) output plugin writes data to the Firebase real-time 
database [via the REST API](https://firebase.google.com/docs/database/rest/retrieve-data). It is based on the excellent 
[rest-firebase](https://github.com/CodementorIO/rest-firebase) Ruby library by the [Codementor](https://www.codementor.io) folks.
Each `firebase` output allows you to write your event data to whatever reference in your Firebase database.

This output plugin supports all [REST operations](https://firebase.google.com/docs/database/rest/save-data#section-ways-to-save) 
provided by Firebase, namely:
 * `put`: to create new data or modify existing data under a specific database reference
 * `patch`: to update some of the keys under a specific database reference without replacing all of the data.
 * `post`: to add new data to a list of data
 * `delete`: to remove data under a specific database reference

The whole event data will be written to Firebase unless the `target` field is configured, in which case only a subset of
the data will be sent to Firebase.

It can be configured very simply as shown below. The event data contained in the `data` sub-field will be written to the path
contained in the event `path` field using the operation contained in the event `verb` field.
 
```
input {
  stdin { codec => 'json' }
}
output {
  firebase {
    url => 'https://test.firebaseio.com'
    auth => 'secret'
    path => '%{path}'
    verb => '%{verb}'
    target => 'data'
  }
}
```

### Configuration

The following list enumerates all configuration parameters of the `firebase` output:

 * `url`: (required) The Firebase URL endpoint
 * `secret`: (optional) The secret to use for authenticating
 * `target`: (optional) The target field whose content will be sent to Firebase. If this setting is omitted, the whole event data will be sent. (default)
 * `verb`: (required) The operation to carry out. Valid operations are `put`, `post`, `patch`, `delete` or a sprintf style string 
 to specify the operation based on the content of the event (full details [here](https://firebase.google.com/docs/database/rest/save-data#section-ways-to-save))
 * `path`: (required) The path to write the event data to. It can also be a sprintf style string to use a path present in the content of the event
   
## Need Help?

Need help? Try #logstash on freenode IRC or the https://discuss.elastic.co/c/logstash discussion forum.

## Developing

### 1. Plugin Developement and Testing

#### Code
- To get started, you'll need JRuby with the Bundler gem installed.

- Create a new plugin or clone and existing from the GitHub [logstash-plugins](https://github.com/logstash-plugins) organization. We also provide [example plugins](https://github.com/logstash-plugins?query=example).

- Install dependencies
```sh
bundle install
```

#### Test

- Update your dependencies

```sh
bundle install
```

- Run tests

```sh
bundle exec rspec
```

### 2. Running your unpublished Plugin in Logstash

#### 2.1 Run in a local Logstash clone

- Edit Logstash `Gemfile` and add the local plugin path, for example:
```ruby
gem "logstash-filter-awesome", :path => "/your/local/logstash-filter-awesome"
```
- Install plugin
```sh
bin/logstash-plugin install --no-verify
```
- Run Logstash with your plugin
```sh
bin/logstash -e 'filter {awesome {}}'
```
At this point any modifications to the plugin code will be applied to this local Logstash setup. After modifying the plugin, simply rerun Logstash.

#### 2.2 Run in an installed Logstash

You can use the same **2.1** method to run your plugin in an installed Logstash by editing its `Gemfile` and pointing the `:path` to your local plugin development directory or you can build the gem and install it using:

- Build your plugin gem
```sh
gem build logstash-filter-awesome.gemspec
```
- Install the plugin from the Logstash home
```sh
bin/logstash-plugin install /your/local/plugin/logstash-filter-awesome.gem
```
- Start Logstash and proceed to test the plugin

## Contributing

All contributions are welcome: ideas, patches, documentation, bug reports, complaints, and even something you drew up on a napkin.

Programming is not a required skill. Whatever you've seen about open source and maintainers or community members  saying "send patches or die" - you will not see that here.

It is more important to the community that you are able to contribute.

For more information about contributing, see the [CONTRIBUTING](https://github.com/elastic/logstash/blob/master/CONTRIBUTING.md) file.
