import os
import json
import logging
from datetime import datetime, time
from flask import Flask, render_template, request, redirect, url_for, session, flash, jsonify

# Set up logging
logging.basicConfig(level=logging.DEBUG)

app = Flask(__name__)
app.secret_key = os.environ.get("SESSION_SECRET", "dev_secret_key_change_in_production")

# Ensure data directory exists
os.makedirs('data', exist_ok=True)

# Class schedule with time restrictions
CLASS_SCHEDULE = {
    'Mathematics': {'start': time(9, 0), 'end': time(10, 0)},
    'Science': {'start': time(10, 30), 'end': time(11, 30)},
    'English': {'start': time(12, 0), 'end': time(13, 0)},
    'Social Studies': {'start': time(14, 0), 'end': time(15, 0)},
    'Hindi': {'start': time(15, 30), 'end': time(16, 30)}
}

def load_students():
    """Load student data from JSON file"""
    try:
        with open('data/students.json', 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        # Create initial student data if file doesn't exist
        students = {}
        for i in range(1, 41):
            roll_number = str(i)
            students[roll_number] = {
                'name': f'Student {i:02d}',
                'roll_number': roll_number,
                'password': f'pass{i:02d}',
                'class': '10'
            }
        save_students(students)
        return students

def save_students(students):
    """Save student data to JSON file"""
    with open('data/students.json', 'w') as f:
        json.dump(students, f, indent=2)

def load_attendance():
    """Load attendance data from JSON file"""
    try:
        with open('data/attendance.json', 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        return {}

def save_attendance(attendance):
    """Save attendance data to JSON file"""
    with open('data/attendance.json', 'w') as f:
        json.dump(attendance, f, indent=2)

def is_class_time(subject):
    """Check if current time falls within the specified class schedule"""
    # Debug mode - allow attendance marking at any time for testing
    debug_mode = os.environ.get('DEBUG_MODE', 'false').lower() == 'true'
    if debug_mode:
        logging.debug(f"DEBUG MODE: Allowing attendance for {subject} at any time")
        return True
    
    current_time = datetime.now().time()
    schedule = CLASS_SCHEDULE.get(subject)
    if not schedule:
        logging.debug(f"No schedule found for subject: {subject}")
        return False
    
    is_time = schedule['start'] <= current_time <= schedule['end']
    logging.debug(f"Time check for {subject}: Current={current_time}, Start={schedule['start']}, End={schedule['end']}, Result={is_time}")
    return is_time

def has_marked_attendance_today(roll_number, subject):
    """Check if student has already marked attendance for the subject today"""
    attendance = load_attendance()
    today = datetime.now().strftime('%Y-%m-%d')
    
    attendance_key = f"{roll_number}_{subject}_{today}"
    return attendance_key in attendance

@app.route('/')
def index():
    if 'roll_number' in session:
        return redirect(url_for('dashboard'))
    return redirect(url_for('login'))

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        roll_number = request.form.get('roll_number')
        password = request.form.get('password')
        
        students = load_students()
        
        if roll_number in students and students[roll_number]['password'] == password:
            session['roll_number'] = roll_number
            session['student_name'] = students[roll_number]['name']
            flash(f'Welcome, {students[roll_number]["name"]}!', 'success')
            return redirect(url_for('dashboard'))
        else:
            flash('Invalid roll number or password. Please try again.', 'error')
    
    return render_template('login.html')

@app.route('/dashboard')
def dashboard():
    if 'roll_number' not in session:
        return redirect(url_for('login'))
    
    # Get today's attendance for this student
    attendance = load_attendance()
    today = datetime.now().strftime('%Y-%m-%d')
    roll_number = session['roll_number']
    
    today_attendance = {}
    for subject in CLASS_SCHEDULE.keys():
        attendance_key = f"{roll_number}_{subject}_{today}"
        today_attendance[subject] = attendance_key in attendance
    
    return render_template('dashboard.html', 
                         today_attendance=today_attendance,
                         class_schedule=CLASS_SCHEDULE)

@app.route('/class_selection')
def class_selection():
    if 'roll_number' not in session:
        return redirect(url_for('login'))
    
    # Check which classes are currently available
    available_classes = {}
    current_time = datetime.now().time()
    
    for subject, schedule in CLASS_SCHEDULE.items():
        is_available = is_class_time(subject)
        has_marked = has_marked_attendance_today(session['roll_number'], subject)
        
        available_classes[subject] = {
            'is_available': is_available,
            'has_marked': has_marked,
            'start_time': schedule['start'].strftime('%I:%M %p'),
            'end_time': schedule['end'].strftime('%I:%M %p')
        }
    
    return render_template('class_selection.html', 
                         available_classes=available_classes,
                         current_time=current_time.strftime('%I:%M %p'))

@app.route('/mark_attendance/<subject>')
def mark_attendance(subject):
    if 'roll_number' not in session:
        return redirect(url_for('login'))
    
    roll_number = session['roll_number']
    
    # Validate subject
    if subject not in CLASS_SCHEDULE:
        flash('Invalid subject selected.', 'error')
        return redirect(url_for('class_selection'))
    
    # Check if it's the right time for this class
    if not is_class_time(subject):
        schedule = CLASS_SCHEDULE[subject]
        flash(f'Attendance for {subject} can only be marked between {schedule["start"].strftime("%I:%M %p")} and {schedule["end"].strftime("%I:%M %p")}.', 'error')
        return redirect(url_for('class_selection'))
    
    # Check if already marked attendance today
    if has_marked_attendance_today(roll_number, subject):
        flash(f'You have already marked attendance for {subject} today.', 'warning')
        return redirect(url_for('dashboard'))
    
    return render_template('mark_attendance.html', subject=subject)

@app.route('/confirm_attendance/<subject>', methods=['POST'])
def confirm_attendance(subject):
    if 'roll_number' not in session:
        return redirect(url_for('login'))
    
    roll_number = session['roll_number']
    student_name = session['student_name']
    
    # Final validation
    if not is_class_time(subject) or has_marked_attendance_today(roll_number, subject):
        flash('Unable to mark attendance. Please try again.', 'error')
        return redirect(url_for('class_selection'))
    
    # Mark attendance
    attendance = load_attendance()
    today = datetime.now().strftime('%Y-%m-%d')
    current_time = datetime.now().strftime('%H:%M:%S')
    
    attendance_key = f"{roll_number}_{subject}_{today}"
    attendance[attendance_key] = {
        'roll_number': roll_number,
        'student_name': student_name,
        'subject': subject,
        'date': today,
        'time': current_time,
        'timestamp': datetime.now().isoformat()
    }
    
    save_attendance(attendance)
    
    flash(f'Attendance marked successfully for {subject}!', 'success')
    return render_template('confirmation.html', subject=subject, time=current_time)

@app.route('/admin')
def admin():
    # Simple admin view - in production, this should have proper authentication
    attendance = load_attendance()
    students = load_students()
    
    # Group attendance by date and subject
    attendance_summary = {}
    for key, record in attendance.items():
        date = record['date']
        subject = record['subject']
        
        if date not in attendance_summary:
            attendance_summary[date] = {}
        if subject not in attendance_summary[date]:
            attendance_summary[date][subject] = []
        
        attendance_summary[date][subject].append(record)
    
    # Sort by date (most recent first)
    sorted_dates = sorted(attendance_summary.keys(), reverse=True)
    
    return render_template('admin.html', 
                         attendance_summary=attendance_summary,
                         sorted_dates=sorted_dates,
                         total_students=len(students))

@app.route('/logout')
def logout():
    session.clear()
    flash('You have been logged out successfully.', 'info')
    return redirect(url_for('login'))

@app.route('/debug/time')
def debug_time():
    """Debug route to show current server time and class availability"""
    current_time = datetime.now()
    debug_info = {
        'current_time': current_time.strftime('%Y-%m-%d %H:%M:%S'),
        'current_time_only': current_time.time().strftime('%H:%M:%S'),
        'class_status': {}
    }
    
    for subject, schedule in CLASS_SCHEDULE.items():
        debug_info['class_status'][subject] = {
            'start': schedule['start'].strftime('%H:%M:%S'),
            'end': schedule['end'].strftime('%H:%M:%S'),
            'is_active': is_class_time(subject)
        }
    
    return f"<pre>{json.dumps(debug_info, indent=2)}</pre>"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
