module Rebugger

using UUIDs
using REPL
import REPL.LineEdit, REPL.Terminals
using REPL.LineEdit: buffer, bufend, content, edit_splice!
using REPL.LineEdit: transition, terminal, mode, state

using Revise
using Revise: ExLike, RelocatableExpr, get_signature, funcdef_body, get_def, striplines!
using Revise: printf_maxsize
using HeaderREPLs

const msgs = []  # for debugging. The REPL-magic can sometimes overprint error messages

include("debug.jl")
include("ui.jl")
include("deepcopy.jl")

# Set up keys that enter rebug mode from the regular Julia REPL
# This should be called from your ~/.julia/config/startup.jl file
function repl_init(repl)
    repl.interface = REPL.setup_interface(repl; extra_repl_keymap = rebugger_modeswitch)
end

function __init__()
    # Set up the Rebugger REPL mode with all of its key bindings
    repl_inited = isdefined(Base, :active_repl)
    @async begin
        while !isdefined(Base, :active_repl)
            sleep(0.05)
        end
        sleep(0.1) # for extra safety
        # Set up the custom "rebug" REPL
        main_repl = Base.active_repl
        repl = HeaderREPL(main_repl, RebugHeader())
        interface = REPL.setup_interface(repl; extra_repl_keymap=[rebugger_modeswitch, rebugger_keys])
        rebug_prompt_ref[] = interface.modes[end]
        # Add F5 to the history prompt
        history_prompt = find_prompt(main_repl.interface, LineEdit.PrefixHistoryPrompt)
        add_key_stacktrace!(history_prompt.keymap_dict)
        # If the REPL was already initialized, add the keys to the julia> prompt now
        # (This will already be done if the user turned on the key bindings in her startup.jl file)
        if repl_inited
            julia_prompt = find_prompt(main_repl.interface, "julia")
            add_key_stacktrace!(julia_prompt.keymap_dict)
            add_key_stepin!(julia_prompt.keymap_dict)
        end
    end
end

end # module
