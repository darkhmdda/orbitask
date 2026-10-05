-- Papelera sincronizada para tareas.
ALTER TABLE public.tasks
ADD COLUMN IF NOT EXISTS trashed_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_tasks_trashed_at
ON public.tasks (trashed_at);
