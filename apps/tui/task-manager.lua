#!/usr/bin/env luajit

-- Note: This is a conceptual TUI app. LTUI would need to be properly installed.
-- For now, this demonstrates the structure and concepts.

local utils = require('libs.shared.utils')
local config = require('libs.shared.config')
local logger = require('libs.shared.logger')

local task_manager = {}

local tasks = {}
local current_task = 1
local view_mode = "list" -- "list", "detail", "add"
local input_buffer = ""

local TASK_STATUS = {
    PENDING = 1,
    IN_PROGRESS = 2,
    COMPLETED = 3,
    CANCELLED = 4
}

local STATUS_NAMES = {
    [1] = "PENDING",
    [2] = "IN PROGRESS", 
    [3] = "COMPLETED",
    [4] = "CANCELLED"
}

local STATUS_COLORS = {
    [1] = 3, -- Yellow
    [2] = 4, -- Blue
    [3] = 2, -- Green
    [4] = 1  -- Red
}

function task_manager.create_task(title, description, priority)
    priority = priority or "medium"
    
    local task = {
        id = #tasks + 1,
        title = title or "New Task",
        description = description or "",
        status = TASK_STATUS.PENDING,
        priority = priority,
        created = os.time(),
        updated = os.time(),
        due_date = nil
    }
    
    table.insert(tasks, task)
    return task
end

function task_manager.update_task(id, updates)
    for i, task in ipairs(tasks) do
        if task.id == id then
            for key, value in pairs(updates) do
                task[key] = value
            end
            task.updated = os.time()
            return task
        end
    end
    return nil
end

function task_manager.delete_task(id)
    for i, task in ipairs(tasks) do
        if task.id == id then
            table.remove(tasks, i)
            if current_task > #tasks then
                current_task = math.max(1, #tasks)
            end
            return true
        end
    end
    return false
end

function task_manager.get_current_task()
    return tasks[current_task]
end

function task_manager.move_selection(direction)
    if direction == "up" then
        current_task = math.max(1, current_task - 1)
    elseif direction == "down" then
        current_task = math.min(#tasks, current_task + 1)
    end
end

function task_manager.load_tasks()
    local config_path = config.get_app_config_path("task-manager")
    local loaded_config = config.load(config_path, {tasks = {}})
    tasks = loaded_config.tasks or {}
    
    for i, task in ipairs(tasks) do
        task.id = i
    end
end

function task_manager.save_tasks()
    local config_path = config.get_app_config_path("task-manager")
    config.save(config_path, {tasks = tasks})
end

local function draw_header()
    print("╔══════════════════════════════════════════════════════════════════════════════╗")
    print("║                              TASK MANAGER                                   ║")
    print("╠══════════════════════════════════════════════════════════════════════════════╣")
    print("║ [Enter] Select  [n] New  [d] Delete  [e] Edit  [s] Status  [q] Quit         ║")
    print("╚══════════════════════════════════════════════════════════════════════════════╝")
    print()
end

local function draw_task_list()
    if #tasks == 0 then
        print("No tasks yet. Press 'n' to create a new task.")
        return
    end
    
    print("ID │ Status      │ Priority │ Title")
    print("───┼─────────────┼──────────┼─────────────────────────────────────────")
    
    for i, task in ipairs(tasks) do
        local marker = (i == current_task) and "►" or " "
        local status_name = STATUS_NAMES[task.status]
        local title = task.title:sub(1, 40)
        
        print(string.format("%s%2d │ %-11s │ %-8s │ %s", 
            marker, task.id, status_name, task.priority, title))
    end
end

local function draw_task_detail()
    local task = task_manager.get_current_task()
    if not task then
        return
    end
    
    print("╔══════════════════════════════════════════════════════════════════════════════╗")
    print("║                               TASK DETAILS                                  ║")
    print("╚══════════════════════════════════════════════════════════════════════════════╝")
    print()
    print("Title:       " .. task.title)
    print("Status:      " .. STATUS_NAMES[task.status])
    print("Priority:    " .. task.priority)
    print("Created:     " .. os.date("%Y-%m-%d %H:%M:%S", task.created))
    print("Updated:     " .. os.date("%Y-%m-%d %H:%M:%S", task.updated))
    print()
    print("Description:")
    print(task.description or "No description")
    print()
    print("Press any key to return to list...")
end

local function draw_new_task_form()
    print("╔══════════════════════════════════════════════════════════════════════════════╗")
    print("║                                NEW TASK                                     ║")
    print("╚══════════════════════════════════════════════════════════════════════════════╝")
    print()
    print("Enter task title: " .. input_buffer)
end

local function handle_input()
    -- This is a simplified input handler. In a real TUI, you'd use proper keyboard input
    io.write("Command: ")
    local input = io.read()
    
    if not input then
        return false
    end
    
    if view_mode == "list" then
        if input == "q" then
            return false
        elseif input == "j" or input == "down" then
            task_manager.move_selection("down")
        elseif input == "k" or input == "up" then
            task_manager.move_selection("up")
        elseif input == "" then -- Enter
            view_mode = "detail"
        elseif input == "n" then
            view_mode = "add"
            input_buffer = ""
        elseif input == "d" then
            local task = task_manager.get_current_task()
            if task then
                print("Delete task '" .. task.title .. "'? (y/N)")
                local confirm = io.read()
                if confirm:lower() == "y" then
                    task_manager.delete_task(task.id)
                end
            end
        elseif input == "s" then
            local task = task_manager.get_current_task()
            if task then
                print("New status (1=Pending, 2=In Progress, 3=Completed, 4=Cancelled):")
                local status = tonumber(io.read())
                if status and status >= 1 and status <= 4 then
                    task_manager.update_task(task.id, {status = status})
                end
            end
        end
    elseif view_mode == "detail" then
        view_mode = "list"
    elseif view_mode == "add" then
        if input == "" then
            if input_buffer ~= "" then
                task_manager.create_task(input_buffer)
            end
            view_mode = "list"
        else
            input_buffer = input
        end
    end
    
    return true
end

local function main_loop()
    while true do
        os.execute("clear")
        
        draw_header()
        
        if view_mode == "list" then
            draw_task_list()
        elseif view_mode == "detail" then
            draw_task_detail()
        elseif view_mode == "add" then
            draw_new_task_form()
        end
        
        if not handle_input() then
            break
        end
    end
end

local function main()
    logger.set_level("ERROR")
    
    print("Task Manager TUI - Starting...")
    print("Note: This is a simplified version. Full TUI requires LTUI library.")
    print()
    
    task_manager.load_tasks()
    
    if #tasks == 0 then
        task_manager.create_task("Welcome Task", "This is your first task. Try editing it!", "high")
        task_manager.create_task("Learn Lua", "Explore the Lua programming language", "medium")
        task_manager.create_task("Build Something", "Create a useful Lua script", "low")
    end
    
    print("Controls:")
    print("  j/k or up/down - Navigate")
    print("  Enter - View details")
    print("  n - New task")
    print("  d - Delete task")
    print("  s - Change status")
    print("  q - Quit")
    print()
    print("Press Enter to start...")
    io.read()
    
    main_loop()
    
    task_manager.save_tasks()
    print("Tasks saved. Goodbye!")
end

if not pcall(main) then
    logger.error("An error occurred during execution")
    os.exit(1)
end