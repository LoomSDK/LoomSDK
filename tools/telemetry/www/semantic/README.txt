This dir contains the necessary source and distribution files for Semantic UI.
If you wish to update the dist files, you need to have "gulp" installed and then run "gulp build" from this directory.
Run just "gulp" to watch the source files for changes, run "gulp help" to view all the available tasks.

If there is no gulpfile, you will probably have to install semantic ui sources (see Semantic UI Source Installation below)


Directory structure:

dist - contains the stripped down, compiled files ready for distribution / packaging (WARNING: do not change the files in this folder as the changes may be lost)
src - contains the source style and script files used in the building process (look up how to change these files instead)
tasks - contains the gulp build task files


## Semantic UI Source Installation

1) node.js - if you don't have it, this would be the time to install it from https://nodejs.org
2) gulp - if you don't have it, install it globally with npm: `npm install -g gulp`
3*) move to the parent www dir and open semantic.json, note down `components` and `components-all` somewhere
4) run `npm install semantic-ui --save` and accept all the defaults (enter should do it)
5*) open semantic.json and add back components and components-all, fix the base path to only use forward slashes if it has back slashes in it
6) you should now be able to cd into semantic/ and run `gulp build`, nice! (if not, file complaints!)

* You don't need these two steps if you just want to tinker, they are required when you want to retain build changes that allow for trimmed down builds meant for production (i.e. when you want to contribute the changes back into the project).