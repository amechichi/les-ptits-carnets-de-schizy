<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

final class ToucherController extends AbstractController
{
    #[Route('/toucher', name: 'app_toucher')]
    public function index(): Response
    {
        return $this->render('toucher/index.html.twig', [
            'controller_name' => 'ToucherController',
        ]);
    }
}
