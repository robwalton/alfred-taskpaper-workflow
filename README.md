# Alfred Taskpaper Workflow

[Alfred 3 workflow](https://www.alfredapp.com/workflows/) to search and create tasks in [TaskPaper 3](https://www.taskpaper.com).

## Install
To install, download the most recent release from [Packal](http://www.packal.org/workflow/taskpaper) and double-click to open in Alfred 2. Alternatively, download what should be the same file released here on github . There are discussion threads on the [TaskPaper forum](http://support.hogbaysoftware.com/t/alfred-2-workflow-for-taskpaper-3/2481) and [Alfred forum](http://www.alfredforum.com/topic/9605-taskpaper3-workflow-for-alfred/).

## Configure document and get help
Use the keywords:
- `d:setdoc` to configure the TaskPapar document the workflow will work on. Most commands will prompt for this before they will work
- `d:choosedoc` to choose the TaskPaper document the workflow will work on via a dialogue box (an alternative to d:setdoc that does not depend on Spotlight to find documents)
- `d:help` to show a brief summary of commands and settings

## View document
Use the keywords:
- `do` to open the workflow’s TaskPaper document. (Also used to create a task —see below.)
- `dosn` show (expand) all notes
- `dohn` hide (collapse) all notes

Use the modifiers:
- none to view the whole document
- ⌘ to view the Inbox
- ⇧ to view the Stack (see below)
- ⌥ to view the 'Reading List' project

The `do` command, along with opening the configured workflow document, will also pop up the results of the _reminder search_ in front of the document. This can be configured using the keyword:
- `d:setremind` to view, change or disable the reminder search

## Create tasks
Use the keywords:
- `do <task>` to create a new task. (Also used to view the document —see above.)
- `domail` to create tasks from emails selected in Apple’s Mail app.
- `dorl` (do 'read later') to create task from Safari page title, URL and highlighted text.

Use the modifiers:
- none to append tasks to a project
- ⌘  to append tasks straight to the Inbox
- ⇧ to add tasks to the top of the Stack (see below)
- ⌥ to add to straight to 'Reading List' project

## Search document
Use the keywords:
- `dos` to search for item and select (see modifiers below).
- `dop` to search for and then focus on a project.
- `doss` to select and apply a search saved from the document.
- `dot` to search for and then append a tag to any current search. Use the modifier _cmd-return_ to instead clear the search before appending the tag.

Use the modifiers on `dos` (search):
- none to select the item in TaskPaper
- ⌘ to toggle the @done tag
- ⇧ to toggle the @today tag

## The Inbox and the Stack
The workflow operates on two special locations:

- **Inbox:** Some commands will operate on a top level project called Inbox. This will be created if need be.
- **Stack:** Some commands will operate on the stack. Technically this is comprised of all items outside a project, but for these commands to make sense these items should be grouped at the top of the document. New items will be added to the top of the stack whereas items added to projects will be added to the bottom.

## Project resources
Projects may have external resources associated with them. These may be files, folders or aliases. They must be stored in the _resource directory_ and are associated with a project by prefixing their name with that of the project. Case does not matter. The resource directory defaults to a location next to the configured TaskPaper document and shares the same name.

Use the keyword:

- `dopr` to open resources associated with a project or to add a folder or alias resource if none exist.

## Thanks
- [dfay](https://www.alfredforum.com/profile/3468-dfay/) and [tschoof](https://www.alfredforum.com/profile/3854-tschoof/) for help with Safari interaction


## Versions
**0.9**
- Initial public release

**0.9.1**
- Fix help command to work when no workflow document has been configured
- Improve `d:setdoc` command so that it now shows all TP docs *before* typeing
- Improve `dop` command to focus on projects properly in all cases
- Improve `dos` command to now show all items before user starts typing
- Add autocomplete to script filters and fix icon references

**0.9.2**
- Fix `dop` (project) command broken in previous release
- Disable the remind screen feature by default
- Add feature to toggle the @done or @today tag via the dos (search) command

**0.9.3**
- `d:setdoc` now warns if Spotlight finds no TaskPaper files and suggesus d:choosedoc
- Create new `d:choosedoc` command to choose a workflow via a dialogue box
- Cursor now correctly moves from sidebar to editor pain when selecting an item
- Fix `do` command with no args to now open workflow doc rather than just bring TP forward
- `domail` command warns if Mail app is closed and no longer creates an empty entry

**0.9.4**
- Fix bug which reults in an extra line under the domail entries
- Update to new TP icon
- Aesthetic changes to make items in Alfred list much simpler looking
- domail now puts URL as comment and uses locale specific date format

**1.0**
- Added `dorl` (rl for read later) command to capture webpage title, URL and highlighted text
- Added `dosn` and `dohn` to show or hide notes respectively
- Collapse notes in items added by `do`, `domail` or `dou`
- Add 'alt' modifier to act on 'Reading List' project

## To contribute
To contribute to the workflow please fork on github: https://github.com/robwalton/alfred-taskpaper-workflow
