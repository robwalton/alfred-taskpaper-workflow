#!/usr/bin/env osascript -l JavaScript


// Archtecture borrows heavily from https://github.com/moranje/alfred-workflow-todoist
// However, did not want to depend on node.js.  JXA does not currently let
// you call script libraries, and so rather than creating many small scripts with
// the same boiler plate code, all code is in here. The single run function
// calls a named function with args.


// Known issues and new features
//
// SHOULD
// - should not automatically make the resource dir folder
// - domail creates an empty entry if Mail app not open - warn
// - search does not seect item if something in the sidbar is selected when run
// COULD
// - domail could work Outlook too
// - work with an alias for the resource dir
// - have a method to set resourcedir, would need to be persisted for each doc
// - have a way to add additional resources to a project
// - opening a directory as a project resource should bring the Finder window forward


// Versions
//
// 0.9
// - Initial public release
//
// 0.9.1
// - Fix help command to work when no workflow document has been configured
// - Improve d:setdoc command so that it now shows all TP docs *before* typeing
// - Improve dop command to focus on projects properly in all cases
// - Improve search command to now show all items before user starts typing
// - Add autocomplete to script filters and fix icon references


ObjC.import('stdlib');
ObjC.import('Foundation');


var WORKFLOW_NAME = 'com.github.robwalton.taskpaper-alfred-workflow'
var DATA_PATH = $.getenv('HOME') + '/Library/Application Support/Alfred 3/Workflow Data/' + WORKFLOW_NAME
DEBUG = true  // JXA logs to error so remember to switch off!


/**
 * run - Called by Alfred for every run of this script. Calls a named function
 * from this script with given arguments
 *
 * @param  {array} argv a list of strings (from Alfred): [functionName, arg1, arg2 ...]
 * @return {type}      result of the called function. Must be a string or something
 * JXA will represent as a string automatically.
 */
function run(argv) {
    functionName = argv[0]
    functionArgs = argv.slice(1)
    log(functionName + '(' + functionArgs.join(', ') + ')')
    return eval(functionName)(...functionArgs)
}


function log(msg) {
    if (DEBUG) {
        console.log(msg)
    }
}


/**
 * _evaluateInTP - Evaluate a function _inside_ TaskPaper
 *
 * @param  {string} func    the function to call
 * @param  {dict} options dictionary of options
 * @return {string}         the result of running the function inside TaskPaper
 */
function _evaluateInTP(func, options) {
    var doc = Application('TaskPaper').open(getDocumentPath())
    return doc.evaluate({
        script: func.toString(),
        withOptions: options
    })
}

///////////////////////////////////////////////////////////////////////////////
// Control TaskPaper (called by Alfred)
///////////////////////////////////////////////////////////////////////////////


/**
 * activateTaskPaper - Activate TaskPaper application
 */
function activateTaskPaper() {
    Application('TaskPaper').activate()
}


/**
 * showProject - Focus on a TaskPaper project
 *
 * @param  {string} id TaskPaper id, or '_all', '_stack' or '_inbox'
 */
function showProject(id) {

    if (id == '_unspecified') {
        // leave the filter as it is
        return
    }

    if (id == '_all') {
        // Open whole doc
        setFocusedItemToId('_root')
        setItemPathFilter('')
    } else if (id == '_stack') {
        // Open scratch items
        setFocusedItemToId('_root')
        setItemPathFilter('/child::* except project')
    } else if (id == '_inbox') {
        setFocusedItemToId('_inbox')
    } else { // a TaskPaper id of a project
        // Open doc in project
        //itemPathFilter = _getAbsolutePathToId(id) + '/descendant-or-self::*'
        setFocusedItemToId(id)
    }

}



/**
 * setItemPathFilter - Set the value in the search field in TaskPaper
 *
 * @param  {string} itemPathFilter Search string
 */
function setItemPathFilter(itemPathFilter) {

    function TPContext(editor, options) {
        editor.itemPathFilter = options.itemPathFilter
    }
    _evaluateInTP(TPContext, {itemPathFilter: itemPathFilter})
}



/**
 * getItemPathFilter - Get the value in the search field in TaskPaper
 *
 * @return {string} Search string
 */
function getItemPathFilter() {

    function TPContext(editor, options) {
        return editor.itemPathFilter
    }
    return _evaluateInTP(TPContext, {})
}

/**
 * setFocusedItemToId - Set the value in the search field in TaskPaper
 *
 * @param  {string} id id of item to focus on or '_root' or '_inbox'
 */
function setFocusedItemToId(id) {

    function TPContext(editor, options) {
        var item
        if (options.id == '_root') {
            item = ''
        } else if (options.id = '_inbox'){
            item = editor.outline.evaluateItemPath('//Inbox')[0]
        } else {
            item = editor.outline.evaluateItemPath('@id = ' + options.id)[0]
        }

        editor.focusedItem = item
    }
    _evaluateInTP(TPContext, {id: id})
}

/**
 * selectItemAndClearFilter - Shows an item in TaskPaper and clears path filter
 *
 * @param  {string} id TaskPaper id to show
 */
function selectItemAndClearFilter(id) {

    function TPContext(editor, options) {
        editor.itemPathFilter = ''
        var item = editor.outline.evaluateItemPath('@id = ' + options.id)[0]
        editor.forceDisplayed(item, true)
        editor.moveSelectionToItems(item)
    }
    _evaluateInTP(TPContext, {id: id})
}


/**
 * createItemsIn - Parse string for items and add to TaskPaper
 *
 * @param  {string} text Items string
 * @param  {string} id   Location, a TaskPaper id or '_inbox' or '_stack'
 * @return {string}      A string to use in a notification
 */
function createItemsIn(text, id) {

    function TPPushToStack(editor, options) {
          var outline = editor.outline;
        //var item = outline.createItem(text)
        var items = ItemSerializer.deserializeItems(options.text, outline, ItemSerializer.TEXTMimeType)
          outline.root.insertChildrenBefore(items, outline.root.firstChild);
    }

    function TPAppendChildrenToProject(editor, options) {
        var outline = editor.outline;
        //var item = outline.createItem(text)
        var items = ItemSerializer.deserializeItems(options.text, outline, ItemSerializer.TEXTMimeType)
        var project = editor.outline.evaluateItemPath('@id = ' + options.id)[0]
        project.appendChildren(items)
    }

    function TPPrependToInbox(editor, options) {
        var outline = editor.outline;

        // Ensure there is an Inbox
        var inbox = outline.evaluateItemPath("//Inbox:")[0];
        if (!inbox) {
            inbox = outline.createItem("Inbox:");
            var projects = editor.outline.evaluateItemPath('@type = project')
            if (projects.length == 0) {
                // Add to end of document
                outline.root.appendChildren(inbox)
            } else {
                // Add before first project
                outline.root.insertChildrenBefore(inbox, projects[0]);
            }
        }
        //var item = outline.createItem(text)
        var items = ItemSerializer.deserializeItems(options.text, outline, ItemSerializer.TEXTMimeType)
        inbox.insertChildrenBefore(items, inbox.firstChild);
    }

    if (id == '_inbox') {
        // Create Inbox if required and append
        _evaluateInTP(TPPrependToInbox, {text: text})
        return "Added to Inbox"
    } else if (id == '_stack') {
        // Add task at top of file
        _evaluateInTP(TPPushToStack, {text: text})
        return "Pushed to stack"
    } else { // a TaskPaper id of a project
        // Append task to project
        _evaluateInTP(TPAppendChildrenToProject, {text: text, id:id})
        return "Added to " + _getAbsolutePathToId(id).slice(1)
    }

}



/**
 * getTasksFromMailSelection - Create parsable string of tasks from currently
 * Selected Mail items.
 *
 * @return {string}  Possibly multiline list, suitable for calls to createItemsIn
 */
function getTasksFromMailSelection() {
    // Code from http://support.hogbaysoftware.com/t/mail-to-tp3-script/1520/6

    selectedMessages = Application("Mail").selection();

    function formatSender(name) {
        name = name.split('<')[0].split('(')[0]
        name = name.split('"').join('')   // remove all quotes
        return name.trim()
    }

    function formatDate(date) {
        return date.toISOString().substring(0, 10)
    }

    function mailURL(id) {
        return 'message://%3C' + id + '%3E'
    }

    items = selectedMessages.map(function(msg) {
        log('===' + formatSender(msg.sender()) + '===')
        return (
            '- Reply to ' + formatSender(msg.sender()) +
            ':- ' + msg.subject() +
            ' (' + formatDate(msg.dateReceived()) + ')' +
            ' ' + mailURL(msg.messageId())
        )
    })
    return items.join('\n')

}


/**
 * generateRemindersText - Create a reminder string based on the configured
 * remind search string
 *
 * @return {string}  Printable reminder summary
 */
function generateRemindersText() {

    var lines = []
    var rs = searchString = getRemindSearchString()
    if (rs === '_remind_disabled') {
        return
    }

    function TPGenerateTextFromSearch(editor, options) {
        var itemList = editor.outline.evaluateItemPath(options.searchString)
        return itemList.map(function(item){
            depth = item.ancestors.length - 1 // The first is birch.js
            return Array(depth + 1).join('     ') + item.bodyString
        })
    }
    log('evaluateing search: ' + rs)
    var itemLines = _evaluateInTP(TPGenerateTextFromSearch, {searchString: rs})

    var maxItems = getRemindSearchMaxItems()
    if (itemLines.length <= maxItems) {
        lines.push(...itemLines)
    } else {
        var trimmed = itemLines.length - maxItems
        lines.push(...itemLines.slice(0, maxItems))
        lines.push('... ' + trimmed + ' items not shown')
    }

    lines.push('')
    lines.push('(configure this remind search with command d:setremind)')
    return lines.join('\n')

}

/**
 * _getAbsolutePathToId - Build the absolute path to a TaskPaper item
 *
 * @param  {string} id TaskPaper id of item
 * @return {string}    Path of projects beginging at '/'
 */
function _getAbsolutePathToId(id) {

    function TPContext(editor, options) {
        var project = editor.outline.evaluateItemPath('@id = ' + options.id)[0]
        path = project.ancestors.splice(1).map(function(a){
            return a.bodyString.replace(':', '');
        });
        path.push(project.bodyString.replace(':', ''))
        return '/' + path.join('/')
    }

    return _evaluateInTP(TPContext, {id: id})

}


///////////////////////////////////////////////////////////////////////////////
// Alfred script filters
//
// JSON format for items defined here:
//     https://www.alfredapp.com/help/workflows/inputs/script-filter/json/
///////////////////////////////////////////////////////////////////////////////


/**
 * getProjectsForScriptFilter - Generate a list of Projects for script filter
 *
 * @return {string}  JSON representation of projects and also '_stack'
 * and '_all'. The arg field is the TaskPaper id (or one of the specials)
 */
function getProjectsForScriptFilter() {

    projects = _evaluateInTP(_TPGenerateProjectItems, {})

    var stackItem = {
        'uid': '_stack',
        'title': '* Stack *',
        'subtitle': '? items',
        'autocomplete': 'Stack',
        'arg': '_stack',
    }

    var allItem = {
        'uid': '_all',
        'title': '* All *',
        'subtitle': projects.length + ' items',
        'autocomplete' : 'All',
        'arg': '_all',
    }

    items = [stackItem, allItem];
    items.push(...projects);
    return JSON.stringify({ "items": items})
}


function getUsedTagsForScriptFilter() {

    function parseForTags(text){
        // Capture an extra '.' at the end of words following an '@'. If this is present the captured word
        // is more than likely part of an email address and we will use this info
        // to chuck it. Not sure what rule TaskPaper actually uses. (Can't get javascript
        // regex to do lookback!)

        var matches = text.match(/(@\w+\.*)/g)
        matches = matches.filter(function(m) {
            return m.slice(-1) != '.'
        })

        return Array.from(new Set(matches))  // Remove duplicates
    }
    var wholeFileString = readFile(getDocumentPath())
    tagArray = ['not @done']
    tagArray.push(...parseForTags(wholeFileString))
    var items = tagArray.map(function(tagname) {
        log(tagname)
        currentPathFilter = getItemPathFilter()
        if (tagname == '@done') {
            var search = tagname
            var subtitle = countFilteredItemsInTP('@done') + ' completed items'
        } else {
            var search = tagname + ' except @done'
            var subtitle = countFilteredItemsInTP(search) + ' items to do'
        }
        if (currentPathFilter == '') {
            var appendedSearch = search
            var appendedSubtitle = subtitle
        } else {
            var appendedSearch = currentPathFilter + ' intersect ' + tagname
            var nitems = countFilteredItemsInTP(appendedSearch)
            var appendedSubtitle = nitems + " items when combined with '" + currentPathFilter + "'"
        }
        return {
            'uid': tagname,
            'title': tagname,
            'autocomplete': tagname,
            'subtitle': appendedSubtitle,
            'arg': appendedSearch,
            "mods": {
                "cmd": {
                    "arg": search,
                    "subtitle": subtitle
                },
            }
        }
    })

    return JSON.stringify({"items": items})

}


function getProjectsResourceForScriptFilter() {

    var resourcedir = getResourceDirectory();
    if (!fileExists(resourcedir)) {
        console.log('Creating directory: ' + resourcedir)
        createDirectory(resourcedir)
    }
    var se = Application('System Events')
    var resourceNames = se.folders.byName(resourcedir.toString()).diskItems.name()
    //log(resourceNames)
    var projects = _evaluateInTP(_TPGenerateProjectItems, {})
    // bodge
    // Replace subtitles with resource action: either open or create directory
    projects.forEach(function (project) {

          projectName = project.title.trim().toLowerCase().replace(':', '')
        // if name prefixes any resource name then add it to a list in arg and
        //  show in subtitle
        matchedNames = resourceNames.filter(function(resourceName){
            return resourceName.toLowerCase().startsWith(projectName)
        })

        resourcePaths = matchedNames.map(function(name) {
            return resourcedir + '/' + name
        })
        project.subtitle = matchedNames.join(' || ')
        if (resourcePaths.length == 0) {
            project.arg = project.title.trim().replace(':', '')
        } else {
            project.arg = JSON.stringify(resourcePaths)
        }

    })
    return JSON.stringify({ "items": projects})
}


function countFilteredItemsInTP(itemPath) {
    function TPContext(editor, options) {
        var itemList = editor.outline.evaluateItemPath(options.itemPath)
        return itemList.length
    }
    return _evaluateInTP(TPContext, {'itemPath': itemPath})
}





function _TPGenerateProjectItems(editor, options) {
    //debugger;
    var itemList = editor.outline.evaluateItemPath('@type = project')
    return itemList.map(function(item){
        repr = item.descendants.map(function(d){
            return d.bodyString;
        });
        repr = repr.join('\n')
        depth = item.ancestors.length - 1 // The first is birch.js
        //debugger
        return {
            'uid': item.id,
            'title': Array(depth + 1).join('      ') + item.bodyString,
            'autocomplete': item.bodyString,
            'subtitle': item.children.length + ' items',
            'arg': item.id,
        }
    })
}


function getSavedSearchesForScriptFilter() {

    // TODO: Code duplicated in scriptFilterRemindSetting()
    items = _evaluateInTP(_TPGetSavedSearches, {})
    return JSON.stringify({"items": items})

}

function _TPGetSavedSearches(editor, options) {
    //debugger
    var itemList = editor.outline.evaluateItemPath('//@search')

    return itemList.map(function(item){
        return {
            'uid': item.id,
            'title': item.bodyContentString,
            'autocomplete': item.bodyContentString,
            'subtitle': item.getAttribute('data-search'),
            'arg': item.getAttribute('data-search'),
        }
    })
}


function scriptFilterSearch(query) {

    function TPQuery(editor, options) {

        q = options.query
        var itemList = editor.outline.evaluateItemPath(q)
        return itemList.map(function(item){
            //depth = item.ancestors.length - 1 // The first is birch.js
            path = item.ancestors.splice(1).map(function(a){
                return a.bodyString;
            });
            datatype = item.getAttribute('data-type')
            console.log(item.bodyString + '--' + item.attributes)
            return {
                //'title': Array(depth + 1).join('      ') + item.bodyString,
                'uid': item.id,
                'title': item.bodyString,
                'autocomplete': item.bodyString,
                'subtitle': path.join('/') + ' (' + datatype + ')',
                'arg': item.id,
            }
        })
    }
    if (query == '') {
        query = '*'
    }
    items = _evaluateInTP(TPQuery, {query: query})
    return JSON.stringify({"items": items})

}

function scriptFilterRemindSetting() {

    var items = []

    items.push({
        'title': '* Leave unchanged *',
        'autocomplete': 'Leave unchanged',
        'subtitle': getRemindSearchString(),
        'arg': getRemindSearchString(),
    })

    var currentValueInTP = getItemPathFilter()
    items.push({
        'title': '* Select current filter from TaskPaper *',
        'autocomplete': 'Select current filter from TaskPaper',
        'subtitle': currentValueInTP,
        'arg': currentValueInTP,

    })

    items.push({
        'title': '* Disable remind popup *',
        'autocomplete': 'Disable',
        'subtitle': '(nagging can be good though)',
        'arg': '_remind_disabled',
    })

    savedSearchItems = _evaluateInTP(_TPGetSavedSearches, {})
    items.push(... savedSearchItems)

    return JSON.stringify({ "items": items})

}


///////////////////////////////////////////////////////////////////////////////
// Settings
///////////////////////////////////////////////////////////////////////////////


function _getSettings() {
    return new PlistSettings(DATA_PATH + '/settings.plist')
}


function setDocumentPath(path) {
    _getSettings().setitem('tpdocument', path)
}

/**
 * getDocumentPath - Return path to TP document configured for workflow
 *
 * @return {type}  'tpdocument' setting or exception if missing
 */
function getDocumentPath() {
    docPath = _getSettings().getitem('tpdocument')
    if (docPath == undefined) {
        _noDocSetAlert()
        throw 'No tpdocument entry in ' + _getSettings().plistPath
    } // else
    return docPath
}

function getResourceDirectory() {
    // var rd = _getSettings().getitem('resourcedir') // if (!rd) {}
    docPath = _getSettings().getitem('tpdocument')

        docDir = docPath.substring(0, docPath.lastIndexOf("/"))
        docName = docPath.substring(docPath.lastIndexOf("/"))
        resourceDir = docDir + docName.substring(0, docName.lastIndexOf("."))

        if (!docName.includes('.')) {
            resourceDir = resourceDir + ' Resources'
        }
        return resourceDir
}


function setRemindSearchString(s) {
    _getSettings().setitem('remindsearch', s)
}

function getRemindSearchString() {
    return _getSettings().getitem('remindsearch') || 'not @done'
}

function _isRemindSearchConfigured() {
    return (_getSettings().getitem('remindsearch') != undefined)
}

function setRemindSearchMaxItems(n) {
    _getSettings().setitem('remindsearchmaxitems', n)
}

function getRemindSearchMaxItems() {
    return _getSettings().getitem('remindsearchmaxitems') || '15'
}

function getSettingsSummary() {

    var remindMsg

    // If no document configured then show a simplified summary
    docPath = _getSettings().getitem('tpdocument')
    if (docPath == undefined) {
        return "!! No document configured for workflow --- configure with 'd:setdoc'"
    }

    var rs = getRemindSearchString()
    if (!_isRemindSearchConfigured()) {
        remindMsg = "defaulting to '" + rs + "'"
    } else if (rs === '_remind_disabled') {
        remindMsg = "*disabled*"
    } else {
        remindMsg ="'" + rs + '"'
    }

    var lines = []
    lines.push("- Document: '" + this.getDocumentPath() +"'")
    lines.push('- Remind search: ' + remindMsg + ' (configure with command d:setremind)')
    lines.push('- Remind max items: ' + getRemindSearchMaxItems())
    lines.push('- Resource Directory: ' + getResourceDirectory())
    return lines.join('\n')

}

function _noDocSetAlert() {
    var app = Application.currentApplication()
    app.includeStandardAdditions = true
    // Message text not strictly true but in normal use is a good compromise
    app.displayAlert(
        'No TaskPaper document selected for workflow',
        {message: 'Select document with command: d:setdoc'}
    )
}




///////////////////////////////////////////////////////////////////////////////
// File access
///////////////////////////////////////////////////////////////////////////////


class PlistSettings {

    constructor(plistPath) {
        this.plistPath = plistPath

        // Create folder and file if missing
        var d = this._readPlist()
        if (d == null || d == undefined) {
            var dir = plistPath.replace('/settings.plist', '')
            log('Ensuring directory exists: ' + dir)
            if (!fileExists(dir)) {
                console.log('Creating directory: ' + dir)
                createDirectory(dir)
            }
            console.log('Creating new plist file: ' + plistPath)
            this._writePlist({})
        }
    }

    setitem(key, value) {
        var d = this._readPlist()
        d[key] = value
        this._writePlist(d)
    }

    getitem(key) {
        return this._readPlist()[key]
    }

    _readPlist() {
        return ObjC.deepUnwrap($.NSDictionary.dictionaryWithContentsOfFile(
                $(this.plistPath).stringByStandardizingPath))
    }

    _writePlist(d) {
        $(d).writeToFileAtomically(
            $(this.plistPath).stringByStandardizingPath, true)
    }

}

function fileTypeString(path) {
    if (!fileExists(path)) {
        throw 'File does not exist: ' + path
    }
    var fileManager = $.NSFileManager.defaultManager
    var attributes = fileManager.attributesOfItemAtPath(
        $(path).stringByStandardizingPath)
    return attributes['NSFileType']
}

function fileExists(path) {
    var fileManager = $.NSFileManager.defaultManager
    return fileManager.fileExistsAtPath($(path).stringByStandardizingPath)
}

function createDirectory(dir) {
    var fileManager = $.NSFileManager.defaultManager
    fileManager.createDirectoryAtPathWithIntermediateDirectoriesAttributesError(
        dir, false, $(), $()
    )
}

function readFile(path) {
    var contents = $.NSFileManager.defaultManager.contentsAtPath(path.toString()); // NSData
    contents = $.NSString.alloc.initWithDataEncoding(contents, $.NSUTF8StringEncoding);
    return ObjC.unwrap(contents)
}
