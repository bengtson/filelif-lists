# Lists

Lists is the **FileliF** Lists application. It manages the Lists compendium and provides a web interface to access the lists.

## List Types

Lists can be either event based or named ordered lists.

## Next Steps

- [ ] Fix FileliF logo and it's position.
- [ ] Write event 'Overdue' evaluation code.
- [ ] Display 'Overdue' events.
- [ ] Add 'Checked' field into evaluation of events.
- [ ] Add checkbox response to server.
- [ ] Add date formatting instead of setting "Checked" to "Yes"
- [ ] Add !Formatted Listed Date to the record so Checked can be set correctly.
- [ ] Need a way to delete a list item. Use a keyboard modifier key that changes from "check" item to "delete" item. icon must change and color should as well.
- [ ] Evaluate events should be done each time a new date is requested. Evaluation should be saved so that it is not done again. More state for dataserver. Actually, keep a list in each item for all the dates that have been evaluated and the results. Extra storage but no biggie.
- [ ] Add an 'Undo' button to reverse the last action.
- [ ] Could each item be a process?
- [ ] Drop next days on the web page. Add next and previous to get to other days.
- [ ] Overdue strategy is to start with current day and make a list of all days back to checked. This will give an overdue count. This only works for checked items. If item is a specific date and only 1, then overdue is all dates between. This strategy takes a while to load but is then easily updated for new dates.

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

### DataServer State
The DataServer has the following state:

  %{ "Lists" => listdata,
     "Instance ID" => unique id for instance or server,
     "Today" => date being used for today,
     "Undo Info" => undo packet}

Instance ID generated with :crypto.strong_rand_bytes(16) |> Base.url_encode64
