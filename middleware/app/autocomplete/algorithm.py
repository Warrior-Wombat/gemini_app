from ..classes.user_session import UserSession

# Usage example
def run_session(user_id: str):
    session = UserSession(user_id)
    
    while True:
        current_input = input("Enter your text (or 'q' to quit): ")
        if current_input.lower() == 'q':
            break
        
        predictions = session.get_predictions(current_input)
        print("Predictions:", predictions)
        
        selected_word = input("Select a word or enter your own: ")
        session.update_model(selected_word)
        
        print("Current conversation:", ' '.join(session.conversation_history))
    
    session.save_user_data()

if __name__ == "__main__":
    run_session("example_user_id")