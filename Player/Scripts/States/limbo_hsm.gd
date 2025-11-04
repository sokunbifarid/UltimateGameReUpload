extends LimboHSM

'''================= States ======================='''

@onready var idle: LimboState = $idle
@onready var walk: LimboState = $walk
@onready var run: LimboState = $run
@onready var stand_jump: LimboState = $stand_jump
@onready var jump: LimboState = $jump

'''================= States ======================='''


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_init_state_machine_()
	
func _init_state_machine_():
	_init_transitions()
	# 	Setup state machine
	initial_state = idle
	initialize(get_parent())
	set_active(true)

func _init_transitions():
	add_transition(ANYSTATE,idle,"to_idle")


	add_transition(walk,run,"to_run")
	add_transition(jump,run,"to_run")

	add_transition(run,walk,"to_walk")
	add_transition(idle,walk,"to_walk")
	add_transition(jump,walk,"to_run")

	add_transition(run,jump,"to_jump")
