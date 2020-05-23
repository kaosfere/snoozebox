local snoozebox = {}

local function start_of_day(timestamp)
    local parts = os.date("*t", timestamp)
    local sod_timestamp = os.time({
        year = parts.year,
        month = parts.month,
        day = parts.day,
        hour = 0
    })
    return sod_timestamp
end

local function add_snooze_header(message, wake_time)
    -- We just stick the header at the top of the messages because it's
    -- easiest, and header order dosen't matter.
    return "X-Snooze-Until: " .. wake_time .. "\r\n" .. message
end

local function remove_snooze_headers(message)
    local snooze_pattern = "X%-Snooze%-Until: (%d+)\r\n"
    local new_string = string.gsub(message, snooze_pattern, "")
    return new_string
end

function snoozebox.go_to_sleep(config)
    local _, mailbox, message, mult, start_time
    local account = config["account"]
    local mailboxes = account:list_all(config["base_folder"], "Snooze_*")
    for _, mailbox in ipairs(mailboxes) do
        local sleep_count, interval = string.match(
            mailbox, config["base_folder"] .. "/Snooze_(%d+)([hdmwy]?)"
        )
        if interval == "h" then mult = 3600             -- hour
            elseif interval == "d" then mult = 86400    -- day
            elseif interval == "w" then mult = 604800   -- week
            elseif interval == "m" then mult = 2592000  -- month
            elseif interval == "y" then mult = 31536000 -- year
            else mult = 1
        end

        local sleep_secs = tonumber(sleep_count) * mult

        -- If we're given a named interval larger than hour, measure it from
        -- the start of the current day.   Otherwise just add seconds to now.
        if mult > 3600 then
            start_time = start_of_day(os.time())
        else
            start_time = os.time()
        end

        local wake_time = start_time + sleep_secs

        local msgs = account[mailbox]:select_all()
        local to_delete = Set{}

        for _, message in ipairs(msgs) do
            local mailbox, uid, text, flags, date, new_text
            mailbox, uid = table.unpack(message)
            text = mailbox[uid]:fetch_message()
            flags = mailbox[uid]:fetch_flags()
            date = mailbox[uid]:fetch_date()
            new_text = add_snooze_header(
                -- avoid duplicate headers by removing old ones
                remove_snooze_headers(text), wake_time 
            )
            table.insert(flags, config["snoozed_tag"])
            if account[config["base_folder"] .. "/Snoozed"]:append_message(
                new_text, flags, date
            ) then
                -- We only add the message to the deletion list if the previous
                -- append was successful -- this way we won't delete a message
                -- that didn't have a snooze-copy made, leaving us with nada.
                table.insert(to_delete, message)
            end
        end

        -- delete the messages we successfully snoozed
        to_delete:delete_messages()
    end
end

function snoozebox.wake_up(config)
    local _, message
    local account = config["account"]
    local msgs = account[config["base_folder"] .. "/Snoozed"]:select_all()
    local to_move = Set{}
    for _, message in ipairs(msgs) do
        local mailbox, uid, snooze_header, snooze_pattern, snooze_time
        mailbox, uid = table.unpack(message)
        snooze_header = mailbox[uid]:fetch_field("X-Snooze-Until")
        snooze_time = tonumber(
            string.match(snooze_header, "X%-Snooze%-Until: (%d+)")
        )
        if snooze_time and snooze_time <= os.time() then
            table.insert(to_move, message)
        end
    end

    to_move:remove_flags({config["snoozed_tag"]})
    to_move:add_flags({config["expired_tag"]})
    to_move:unmark_seen()
    to_move:move_messages(account.INBOX)
end

return snoozebox