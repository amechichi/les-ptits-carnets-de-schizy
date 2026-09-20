// Menu mobile : affiche / masque la navigation (le style vit dans styles/header.css)
const bouton = document.querySelector('.bouton-menu');
const nav = document.querySelector('nav.liens');

if (bouton && nav) {
    bouton.addEventListener('click', () => {
        const ouvert = nav.classList.toggle('est-ouvert');
        bouton.setAttribute('aria-expanded', String(ouvert));
    });
}
