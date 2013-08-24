/*-----------------------------
--- WINDOW CALLBACK HELPERS ---
-----------------------------*/

 // Execute an array of functions.
function executeArray( arr ) {
    _.each( arr, function( fn ) {
        fn();
    } );
}

// Make it easy to aggregate scroll callbacks.
var scrollCallbacks = [];

function onScroll( fn ) {
    scrollCallbacks.push( fn );
    return fn;
}

$( window ).scroll( function() {
    executeArray( scrollCallbacks );
} );