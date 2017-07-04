My thoughts
=====
I think it's better to reinvent the Importer from scratch than try to refactor the existed mess.
In the code I found some mistakes, redundant variables, not effective algorithms, etc.

Unfortunately, I don't know all requirements to the Exporter, otherwise I could suggest better solution.
But let's suppose we should start with that we have at the moment.

In the first iteration I'd split the code into entities using Single Responsibility Principle.
Independent entities are easier to test, easier to refactor.
For example, we could start with:

FTP class, which is responsible for files gathering, uploading, etc. We could use this class as a Main Class of the Importer for a while, like: CSVImporter::FTP.new.import

Since FTP object returned some files we could path them to another Class — File.
After some validations the file instance produces rows. Thus, the rows could be managed by Row class.

The Row class should check the activity transaction type and use the chosen one for the last operation — to create a transaction.

Each Transaction Class is just a Strategy. We can easily add more strategies later.

Looks better, isn't?

The second iteration might be to pull out all global settings to some Config Object.
Implementation of the Config Object could help us to change all settings in the one place.

The third iteration will be about optimisation. For example, it's faster to download all files at once in parallel, than do it one by one between the import process.

Or, for example, why we should stop the import process if some of the file gets error? Let's keep going, all we have to do is just to mark this file as failed one.

Why don'we send just one email with the total status when the Import Process is finished? It could contain the list of imported files, their statuses, errors, ids of rows, etc.

Depending of the subsequent requirements, we could go further with the refactoring.

Why don't we want to pack it as a gem or a Rails plugin? Or even two and more independent gems? It will be usefull, if we're going to use the Importer or its parts in differents platforms with a little changes.

Actually, I didn't know that the task is for two hours only :)
So I was working on it for 2 days until I knew the conditions.

I tried to understand how it works, what's the features list, the main idea or the purpose of the script. To do this I wrote down, step by step, all main functions, and started to implement them from scratch.

So, now I stopped working after two days and here you can take a look at what I've done so far. What's next? It's still needed to finish some refactoring, to dry the code. Add much more tests. And it would be nice to hear some comments from the product owner, to discuss the requirements :)


Task
=====

The code presented in the task is running in a cronjob every 1 hour as the following task:

```ruby
namespace :mraba do
  task :import do
    CsvExporter.transfer_and_import
  end
end
```

It is connecting via FTP to the "Mraba" service and importing list of transactions from there. The code have the following issues:

* runs very slow
* when occasionally swallow errors
* tests for the code are unreliable and incomplete
* had for new team members to get around it
* not following coding standards

__Instalation__

```
bundle
```

__Test running__
```
rake
```
