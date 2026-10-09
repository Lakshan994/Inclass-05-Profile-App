
import { useState } from "react";
import "./App.css";
import profileImage from "./assets/profile.png";

function App() {
  const [points, setPoints] = useState(0);

  const user = {
    name: "Lakshan Aroshana",
    email: "gylayapa@students.nsbm.ac.lk",
  };

  const addPoint = () => {
    setPoints((previousPoints) => previousPoints + 1);
  };

  return (
    <div className="app-container">
      <div className="profile-page">

        {/* App Bar */}
        <header className="app-bar">
          <h1>My Profile</h1>
        </header>

        <main className="profile-content">

          {/* Profile Image */}
          <div className="avatar-section">
            <div className="avatar-wrapper">
              <img
                src={profileImage}
                alt="Profile Avatar"
                className="profile-image"
              />
            </div>
          </div>

          <hr className="divider" />

          {/* Name */}
          <section className="info-section">
            <h3>Name</h3>
            <p>{user.name}</p>
          </section>

          {/* Email */}
          <section className="info-section">
            <h3>Email</h3>
            <div className="info-row">
              <span className="info-icon">✉</span>
              <p>{user.email}</p>
            </div>
          </section>

          {/* Points */}
          <section className="info-section">
            <h3>Points</h3>
            <div className="info-row">
              <span className="info-icon">★</span>
              <p>{points}</p>
            </div>
          </section>
        </main>

        {/* Floating Action Button */}
        <button
          className="floating-button"
          onClick={addPoint}
          aria-label="Add point"
          title="Add point"
        >
          +
        </button>
      </div>
    </div>
  );
}

export default App;
