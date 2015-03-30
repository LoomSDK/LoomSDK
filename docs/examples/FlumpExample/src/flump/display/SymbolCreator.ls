package flump.display {

import loom2d.display.DisplayObject;

interface SymbolCreator {
    function create (library :Library) :DisplayObject;
}
}
