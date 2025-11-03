extends Node3D

func _on_gpu_particles_3d_finished():
	queue_free() # This line destroys the spark effect
