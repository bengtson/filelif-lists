# Lists

Lists is the **FileliF** Lists application. It manages the Lists compendium and provides a web interface to access the lists.

## Update Planning

Lists needs to have some additional flexibility to better manage my days.
Following are some of the items that need to be added.

- While I like 'bullet' journaling in a notebook, it doesn't allow for all the events that I use in 'Lists'. It also does not layout my day like I've started to do for work with project tracking.
- Items in lists need to be able to be entered in lists.
- Lists need to be nested so that 'home:build:vanity' has a list specific to vanity. Or 'work:papyrus-imaging:camera-software' has the list to do for camera software.
- List items are really just events too. Call them entries.
- Entries can have history attached to them so that I can see what was changed in the past for an event.
- Entries can have complex repeats, triggers in, triggers out, start/end times or dates, and completion %.
- Should be able to build a day list from options that are scheduled.
- Have Indicia display (in bedroom) giving what the day looks like.
- There should be an API to Lists that would allow a list to be extracted and processed and maybe placed back into the system.
- Should be GraphQL ability to search lists.



## List Types

Lists can be either event based or named ordered lists.

## Next Steps

- If entry has a note, add it to the hover information.
- Add list items to the system.
- The users list instance should be held in their sessionmanager. Set the
- instance each time there is a call from the browser.
- If the instance is different in plug :session_manager, redirect to "/", halt.
- When add event is clicked the following should occur:
  - call to addeventpage.example_page conn : This will set the text for the example event. The example should be evaluated. Then the example event and the evaluation should be shown.
  - pressing evaluate will evaluate the event and rewrite the page.
  - pressing add will cause the event to be added to the list. This will be done by DataServer add_list_record.
- Add Search Capability To Events
- Add Lists Display Capability
- [ ] Show New Event meta data when "Evaluate" pressed.
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

## Road Map
Integrate the Bullet Journal approach into the system. Each day a printout of what needs to be done can be provided. End of day, add what's been put on paper back into the system.

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
