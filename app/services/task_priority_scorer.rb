class TaskPriorityScorer
  # Urgency boosts (Tier 1: strictly outranks upcoming and undated tasks)
  OVERDUE_BOOST   = 2_000
  DUE_TODAY_BOOST = 1_000

  # Priority base scores
  PRIORITY_SCORES = {
    "urgent" => 400,
    "high"   => 300,
    "medium" => 200,
    "low"    => 100
  }.freeze

  # Proximity boosts for upcoming tasks (in days)
  PROXIMITY_BOOSTS = {
    1 => 50, # Due tomorrow
    3 => 30, # Due in 2-3 days
    7 => 15  # Due within 7 days
  }.freeze
  DEFAULT_UPCOMING_BOOST = 5

  def self.rank(tasks, reference_date: Time.zone.today)
    new(tasks, reference_date: reference_date).rank
  end

  def initialize(tasks, reference_date: Time.zone.today)
    @tasks = tasks
    @reference_date = reference_date
  end

  def rank
    # Exclude completed tasks from the active Today queue
    active_tasks = @tasks.reject(&:completed?)

    active_tasks.each do |task|
      task.priority_score = calculate_score(task)
      task.ranking_reason = determine_reason(task)
    end

    active_tasks.sort { |a, b| compare(a, b) }
  end

  private

  def calculate_score(task)
    score = PRIORITY_SCORES.fetch(task.priority, 100)

    if task.due_at.present?
      due_date = task.due_at.to_date
      days_diff = (due_date - @reference_date).to_i

      if days_diff < 0
        score += OVERDUE_BOOST
      elsif days_diff == 0
        score += DUE_TODAY_BOOST
      elsif days_diff == 1
        score += PROXIMITY_BOOSTS[1]
      elsif days_diff <= 3
        score += PROXIMITY_BOOSTS[3]
      elsif days_diff <= 7
        score += PROXIMITY_BOOSTS[7]
      else
        score += DEFAULT_UPCOMING_BOOST
      end
    end

    score
  end

  def determine_reason(task)
    if task.due_at.present?
      due_date = task.due_at.to_date
      days_diff = (due_date - @reference_date).to_i

      if days_diff < 0
        days_ago = days_diff.abs
        days_ago == 1 ? "Overdue (1 day)" : "Overdue (#{days_ago} days)"
      elsif days_diff == 0
        "Due today"
      elsif days_diff == 1
        "Due tomorrow"
      elsif task.priority == "urgent"
        "Urgent priority"
      elsif task.priority == "high"
        "High priority"
      elsif days_diff <= 3
        "Due in #{days_diff} days"
      else
        "#{task.priority.humanize} priority"
      end
    else
      if task.priority == "urgent"
        "Urgent priority"
      elsif task.priority == "high"
        "High priority"
      else
        "#{task.priority.humanize} priority"
      end
    end
  end

  def compare(a, b)
    # 1. Higher score first
    score_comp = b.priority_score <=> a.priority_score
    return score_comp unless score_comp.zero?

    # 2. Tie-breaker: oldest deadline first (due_at ASC)
    if a.due_at.present? && b.due_at.present?
      due_comp = a.due_at <=> b.due_at
      return due_comp unless due_comp.zero?
    elsif a.due_at.present? && b.due_at.blank?
      return -1
    elsif a.due_at.blank? && b.due_at.present?
      return 1
    end

    # 3. Tie-breaker: oldest created_at first (created_at ASC)
    if a.created_at.present? && b.created_at.present?
      created_comp = a.created_at <=> b.created_at
      return created_comp unless created_comp.zero?
    end

    # 4. Ultimate tie-breaker: id ASC
    (a.id || 0) <=> (b.id || 0)
  end
end
