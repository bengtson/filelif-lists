# Lists

Lists is the **FileliF** Lists application. It manages the Lists compendium and provides a web interface to access the lists.

## List Types

Lists can be either event based or named ordered lists.

## Next Steps

- [ ] Bold DUE when due page is shown.
- [ ] Create Add Event Page
- [ ] Running tests loads the lists file and it should not. Figure out how to distinguish between production and development testing.
- [ ] Keep list in each record of the date/match values.
- [ ] Write timer to reevaluate events at midnight.
- [ ] Fix FileliF logo and it's position.
- [ ] Remove events that are complete.
- [ ] Create archive list files with date of archiving. When?
- [ ] Need a way to delete a list item. Use a keyboard modifier key that changes from "check" item to "delete" item. icon must change and color should as well.
- [ ] Evaluate events should be done each time a new date is requested. Evaluation should be saved so that it is not done again. More state for dataserver. Actually, keep a list in each item for all the dates that have been evaluated and the results. Extra storage but no biggie.
- [ ] Add an 'Undo' button to reverse the last action.
- [ ] Could each item be a process?
- [ ] Consider changing the list of records into a map of records based on record id.

-define(INTERVAL, 60000). % One minute

init(Args) ->
   ... % Start first timer
   erlang:send_after(?INTERVAL, self(), trigger),
   ...

handle_info(trigger, State) ->
   ... % Do the action
   ... % Start new timer
   erlang:send_after(?INTERVAL, self(), trigger),
   ...

## Storing Event Date Information
It's complicated tracking an event for a number of reasons. Events can be overdue and calculating how many times it's been due is not easy.

Here's how it's going to be done ...

There will be a map entry in the record called "Eval Data" => eval map.
This points to an info map that has the following:

    %{ "Overdue First Date" => date when event was first overdue,
       "Overdue Last Date" => this should always be the day before 'today',
       "Overdue Match Count" => number of times this has been overdue,
       "Dates" => future eval dates map}

The 'future eval dates map' provides specific date match information. A map would look like this assuming today is 24-May-2016:

    %{ "24-May-2016" => true,
       "25-May-2016" => false }

When midnight strikes, it's easy to update the !Eval Info table. The match information for 'today' (or yesterday if after midnight) must be folded into the overdue table. Change the Last Date entry to 'today' and if the value was true, then increment the match count. Remove the 'today' entry and generate a new one if it does not exist.

### Meta Info Map
All data added to records read from the file will have a Meta Data record as follows:

  %{ "Meta Data" => meta data map }

  The meta data map as the following entries:

  %{ "Eval Data" => eval map,
     "Record ID" => record_id }
