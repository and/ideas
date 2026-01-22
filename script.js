// Simple script to add interactivity
document.addEventListener('DOMContentLoaded', function() {
    const greeting = document.getElementById('greeting');

    // Add a click event to change colors
    greeting.addEventListener('click', function() {
        const colors = ['#667eea', '#f093fb', '#4facfe', '#43e97b', '#fa709a'];
        const randomColor = colors[Math.floor(Math.random() * colors.length)];
        greeting.style.color = randomColor;
    });

    console.log('Hello World app loaded successfully!');
});
